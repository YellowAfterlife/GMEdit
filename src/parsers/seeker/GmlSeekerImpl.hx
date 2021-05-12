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
	
	public var swapReader:GmlReaderExt = null;
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
	
	public var localKind:AceTokenType;
	public var subLocalDepth:Null<Int> = null;
	
	public var notLam:Bool;
	public var canLam:Bool;
	public var canDefineComp:Bool;
	public var isObject:Bool;
	public var isCreateEvent:Bool;
	public var specTypeInst:Bool;
	
	public var funcsAreGlobal:Bool;
	public var hasFunctionLiterals:Bool;
	public var hasTryCatch:Bool;
	public var jsDoc:GmlSeekerJSDoc = new GmlSeekerJSDoc();
	
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
		
		notLam = !(kind is KGmlLambdas);
		canLam = !notLam && project.canLambda();
		canDefineComp = (kind is KGml) && (cast kind:KGml).canDefineComp;
		funcsAreGlobal = GmlFileKindTools.functionsAreGlobal(kind);
		
		isObject = (kind is KGmlEvents);
		isCreateEvent = isObject && (locals.name == "create"
			|| JsTools.rx(~/\/\/\/\s*@init\b/).test(src)
		);
		
		var additionalKeywordsMap = version.config.additionalKeywordsMap;
		hasFunctionLiterals = additionalKeywordsMap.exists("function");
		hasTryCatch = additionalKeywordsMap.exists("catch");
		
		specTypeInst = GmlLinter.getOption((p) -> p.specTypeInst);
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
	
	public function setLookup(s:String, eol:Bool = false):Void {
		var col = eol ? null : 0;
		GmlAPI.gmlLookup.set(s, { path: orig, sub: sub, row: reader.row, col: col });
		if (s != mainTop) GmlAPI.gmlLookupList.push(s);
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
				Main.console.warn("old", oldPos, oldSource.length);
				Main.console.warn("new", q.pos, q.source.length, q.source == oldSource);
			}
			oldPos = q.pos;
			oldSource = q.source;
			//*/
			var flags = Ident | Doc | Define | Macro;
			if (exitAtCubDepth != null || funcsAreGlobal) flags |= Cub1;
			var s = find(flags);
			if (s == null) continue;
			if (s.fastCodeAt(0) == "/".code) { // JSDoc
				jsDoc.proc(this, s);
				continue;
			}
			// (known to not be JSDoc from hereafter):
			switch (s) {
				case "}": {
					if (curlyDepth <= 0 && funcsAreGlobal && docIsAutoFunc) {
						flushDoc();
						main = null;
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
						s = find(Ident | Semico);
						if (s == null || s == ";" || GmlAPI.kwFlow.exists(s)) break;
						var g = new GmlGlobalVar(s, orig);
						out.globalVars[s] = g;
						if (privateGlobalRegex == null || !privateGlobalRegex.test(s)) {
							out.comps[s] = g.comp;
						}
						out.kindList.push(s);
						out.kindMap.set(s, "globalvar");
						setLookup(s);
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
				case "var": {
					GmlSeekerProcVar.proc(this);
				};
				case "enum": {
					GmlSeekerProcEnum.proc(this);
				};
				default: { // maybe an instance field assignment
					GmlSeekerProcIdent.proc(this, s);
				};
			} // switch (s)
		} // while in doLoop, can continue
	} // doLoop
	
	public function run() {
		var q = reader;
		if (main != null) setLookup(main);
		mainComp = main != null ? GmlAPI.gmlAssetComp[main] : null;
		var s:String, name:String;
		//
		doLoop();
		flushDoc();
		//
		if (project.hasGMLive) out.hasGMLive = out.hasGMLive || ui.GMLive.check(src);
	}
}