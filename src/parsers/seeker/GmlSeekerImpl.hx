package parsers.seeker;
import ace.extern.AceAutoCompleteItem;
import ace.extern.AceTokenType;
import file.FileKind;
import file.kind.KGml;
import file.kind.gml.KGmlEvents;
import file.kind.gml.KGmlLambdas;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.GmlGlobalField;
import gml.GmlGlobalVar;
import gml.GmlLocals;
import gml.GmlVersion;
import gml.Project;
import gml.file.GmlFileKindTools;
import gml.type.GmlTypeDef;
import haxe.io.Path;
import js.lib.RegExp;
import parsers.GmlReaderExt;
import parsers.GmlSeekData;
import parsers.linter.GmlLinter;
import parsers.seeker.GmlSeekerJSDoc;
import parsers.seeker.GmlSeekerParser;
import parsers.seeker.GmlSeekerProcEnum;
import synext.GmlExtLambda;
import tools.Aliases;
import tools.IntDictionary;
import tools.JsTools;
import tools.RegExpCache;
import ui.ext.GMLive;
using tools.NativeArray;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerImpl {
	public var version:GmlVersion;
	public var project:Project;
	
	public var reader:GmlReaderExt;
	public var swapReader:GmlReaderExt;
	public function saveReader():Void {
		if (swapReader == null) swapReader = new GmlReaderExt(src);
		swapReader.setTo(reader);
	}
	public inline function restoreReader():Void {
		reader.setTo(swapReader);
	}
	
	public var src:GmlCode;
	public var orig:FullPath;
	public var main:String;
	public var mainTop:GmlName;
	public var sub:String = null;
	public var doc:GmlFuncDoc = null;
	public var docIsAutoFunc = false;
	public var mainComp:AceAutoCompleteItem;
	
	/** Where the current scope starts */
	public var start:StringPos = 0;
	
	public var locals:GmlLocals;
	public var kind:FileKind;
	public var out:GmlSeekData;
	
	public var curlyDepth:Int = 0;
	public var withStartsAtCurlyDepth:Int = -1;
	
	public var localKind:AceTokenType;
	public var subLocalDepth:Null<Int> = null;
	
	public var notLam:Bool;
	public var canLam:Bool;
	public var canDefineComp:Bool;
	public var isObject:Bool;
	public var isCreateEvent:Bool;
	public var specTypeInst:Bool;
	public var specTypeInstSubTopLevel:Bool;
	public var strictStaticJSDoc:Bool;
	
	public var funcsAreGlobal:Bool;
	public var hasFunctionLiterals:Bool;
	public var hasTryCatch:Bool;
	public var jsDoc:GmlSeekerJSDoc = new GmlSeekerJSDoc();
	public var isLibraryResource:Bool;
	
	public var commentLineJumps = new IntDictionary<Int>();
	
	public var privateFieldRegex:RegExp;
	public var privateGlobalRegex:RegExp;
	
	var __objectName:String = null;
	public function getObjectName():String {
		if (__objectName == null) {
			var p = new Path(orig);
			p.dir = null;
			if (p.ext.toLowerCase() == "gmx") { // .object.gmx
				__objectName = Path.withoutExtension(p.file);
			} else __objectName = p.file;
		}
		return __objectName;
	}
	
	public function new(
		fullPath:FullPath,
		code:GmlCode,
		main:GmlName,
		out:GmlSeekData,
		locals:GmlLocals,
		kind:FileKind
	) {
		this.src = code;
		this.orig = fullPath;
		this.main = main;
		this.out = out;
		this.locals = locals;
		this.kind = kind;
		mainTop = main;
		
		project = Project.current;
		version = project.version;
		reader = new GmlReaderExt(code, version);
		swapReader = new GmlReaderExt(code, version);
		
		notLam = !(kind is KGmlLambdas);
		canLam = !notLam && project.canLambda();
		canDefineComp = (kind is KGml) && (cast kind:KGml).canDefineComp;
		funcsAreGlobal = GmlFileKindTools.functionsAreGlobal(kind);
		isLibraryResource = project.libraryResourceMap[main];
		
		isObject = (kind is KGmlEvents);
		isCreateEvent = isObject && (locals.name == "create"
			|| JsTools.rx(~/\/\/\/\s*@init\b/).test(src)
		);
		
		var additionalKeywordsMap = version.config.additionalKeywordsMap;
		hasFunctionLiterals = additionalKeywordsMap.exists("function");
		hasTryCatch = additionalKeywordsMap.exists("catch");
		
		specTypeInst = GmlLinter.getOption(p -> p.specTypeInst);
		specTypeInstSubTopLevel = GmlLinter.getOption(p -> p.specTypeInstSubTopLevel);
		strictStaticJSDoc = GmlLinter.getOption(p -> p.strictStaticJSDoc);
		localKind = notLam ? "local" : "sublocal";
		if (project.properties.lambdaMode == Scripts) {
			if (orig.contains("/" + GmlExtLambda.lfPrefix)) {
				canLam = true;
				localKind = "sublocal";
			}
		}
		
		privateFieldRegex = privateFieldRC.update(project.properties.privateFieldRegex);
		privateGlobalRegex = privateGlobalRC.update(project.properties.privateGlobalRegex);
	}
	private static var privateFieldRC:RegExpCache = new RegExpCache();
	private static var privateGlobalRC:RegExpCache = new RegExpCache();
	
	public inline function find(flags:GmlSeekerFlags):String {
		return GmlSeekerParser.find(this, flags);
	}
	
	public function setLookup(s:String, eol:Bool, meta:String):Void {
		var col = eol ? null : 0;
		var row = reader.row;
		if (!GmlAPI.gmlLookup.exists(s)
			&& s != mainTop
			&& !isLibraryResource
		) {
			GmlAPI.gmlLookupItems.push({ value:s, meta:meta });
		}
		var lookup:GmlLookup = { path: orig, sub: sub, row: row, col: col };
		if (project.isGMS23 && s == mainTop) {
			lookup.sub = null;
			lookup.row = 0;
		}
		GmlAPI.gmlLookup[s] = lookup;
	}
	
	public function linkDoc():Void {
		if (doc != null) out.docs[main] = doc;
	}
	
	public inline function flushDoc():Void {
		GmlSeekerProcDoc.flush(this);
	}
	
	public function doLoop(?exitAtCubDepth:Int) {
		var q = reader;
		while (q.loop) {
			/*//
			if (q.pos < oldPos && debug) {
				Console.warn("old", oldPos, oldSource.length);
				Console.warn("new", q.pos, q.source.length, q.source == oldSource);
			}
			oldPos = q.pos;
			oldSource = q.source;
			//*/
			var flags = Ident | Doc | Define | Macro;
			if (exitAtCubDepth != null || funcsAreGlobal || withStartsAtCurlyDepth >= 0) flags |= Cub1;
			var s = find(flags);
			if (s == null) continue;
			if (s.fastCodeAt(0) == "/".code) { // JSDoc
				if (s.fastCodeAt(1) == "*".code) {
					jsDoc.procMultiLine(this, s);
				} else jsDoc.proc(this, s);
				continue;
			}
			// (known to not be JSDoc from hereafter):
			switch (s) {
				case "}": {
					if (curlyDepth <= 0 && funcsAreGlobal && docIsAutoFunc) {
						flushDoc();
						main = null;
					}
					if (withStartsAtCurlyDepth >= 0 && curlyDepth < withStartsAtCurlyDepth) {
						withStartsAtCurlyDepth = -1;
					}
					if (exitAtCubDepth != null && curlyDepth <= exitAtCubDepth) return;
				};
				case "#define", "#target", "function": {
					// we don't have to worry about #event/etc because they
					// do not occur in files themselves
					GmlSeekerProcDefine.proc(this, s);
				};
				case "#macro": {
					GmlSeekerProcMacro.proc(this);
				};
				case "globalvar": {
					while (q.loop) {
						saveReader();
						q.skipSpaces1();
						if (!q.peek().isIdent0_ni()) break;
						var name = q.readIdent();
						if (GmlAPI.kwFlow.exists(name)) {
							restoreReader();
							break;
						}
						
						var g = new GmlGlobalVar(name, orig);
						out.globalVars[name] = g;
						if (privateGlobalRegex == null || !privateGlobalRegex.test(name)) {
							out.comps[name] = g.comp;
						}
						out.kindList.push(name);
						out.kindMap.set(name, "globalvar");
						setLookup(name, false, "globalvar");
						
						saveReader();
						q.skipSpaces1();
						if (q.peek() == "/".code
							&& q.peek(1) == "*".code
							&& q.peek(2) == ":".code
						) {
							q.skip(3);
							var typeStart = q.pos;
							q.skipComment();
							var typeStr = q.substring(typeStart, q.pos - 2);
							var type = GmlTypeDef.parse(typeStr, "globalvar");
							out.globalVarTypes[name] = type;
							saveReader();
							q.skipSpaces1();
						}

						if (q.peek() != ",".code) {
							restoreReader();
							break;
						} else q.skip();
					}
				};
				case "global": {
					if (find(Period | Ident) == ".") {
						s = find(Ident);
						if (s != null && !out.globalFields.exists(s)) {
							var gfd = GmlAPI.gmlGlobalFieldMap[s];
							var hide = privateGlobalRegex != null && privateGlobalRegex.test(s);
							if (gfd == null) {
								gfd = new GmlGlobalField(s);
								gfd.hidden = hide;
								GmlAPI.gmlGlobalFieldMap.set(s, gfd);
							}
							out.globalFields[s] = gfd;
							if (!hide) out.globalFieldComp.push(gfd.comp);
						}
					}
				};
				case "catch" if (hasTryCatch): {
					var name = find(Ident);
					locals.add(name, localKind, "try-catch");
				};
				case "var"|"static": {
					GmlSeekerProcVar.proc(this, s);
				};
				case "enum": {
					GmlSeekerProcEnum.proc(this);
				};
				case "with": GmlSeekerProcWith.proc(this);
				default: { // maybe an instance field assignment
					GmlSeekerProcIdent.proc(this, s);
				};
			} // switch (s)
		} // while in doLoop, can continue
	} // doLoop
	
	public function run() {
		var q = reader;
		if (main != null) setLookup(main, false, null);
		mainComp = main != null ? GmlAPI.gmlAssetComp[main] : null;
		var s:String, name:String;
		//
		doLoop();
		flushDoc();
		//
		if (project.hasGMLive) out.hasGMLive = out.hasGMLive || ui.ext.GMLive.check(src);
	}
}