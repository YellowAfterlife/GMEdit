package parsers;
import gml.file.GmlFileKindTools;
import ace.AceGmlTools;
import ace.extern.*;
import electron.FileSystem;
import electron.FileWrap;
import file.FileKind;
import file.kind.*;
import file.kind.gml.*;
import file.kind.gmx.*;
import file.kind.yy.*;
import gml.GmlAPI;
import gmx.*;
import yy.*;
import gml.*;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTools;
import gml.type.GmlTypeTemplateItem;
import haxe.io.Path;
import js.lib.Error;
import js.lib.RegExp;
import parsers.GmlReader;
import parsers.GmlSeekData;
import parsers.linter.GmlLinter;
import synext.GmlExtLambda;
import synext.GmlExtMFunc;
import tools.CharCode;
import tools.Dictionary;
import tools.Aliases;
import tools.JsTools;
import tools.RegExpCache;
import ui.Preferences;
import ui.treeview.TreeView;
import yy.YyObject;
using StringTools;
using tools.NativeString;
using tools.NativeArray;
using tools.PathTools;

/**
 * Looks for definitions in files/code (for syntax highlighing, auto-completion, etc.)
 * @author YellowAfterlife
 */
class GmlSeeker {
	public static inline var maxAtOnce = 16;
	public static var itemsLeft:Int = 0;
	static var itemQueue:Array<GmlSeekerItem> = [];
	static var lastLabelUpdateTime:Float = 0;
	public static function start() {
		itemsLeft = 0;
		itemQueue.resize(0);
	}
	private static function runItem(item:GmlSeekerItem) {
		itemsLeft++;
		FileWrap.readTextFile(item.path, function ready(err:Error, text:String) {
			if (err != null) {
				Main.console.error("Can't index ", item.path, err);
				runNext();
			} else try {
				if (runSync(item.path, text, item.main, item.kind)) {
					runNext();
				}
			} catch (err:Dynamic) {
				Main.console.error("Can't index ", item.path, err);
				runNext();
			}
		});
	}
	public static function run(path:FullPath, main:GmlName, kind:FileKind) {
		var item:GmlSeekerItem = {path:path.ptNoBS(), main:main, kind:kind};
		if (itemsLeft < maxAtOnce) {
			runItem(item);
		} else itemQueue.push(item);
	}
	public static function runFinish():Void {
		GmlAPI.gmlComp.autoSort();
		if (Project.current != null) Project.current.finishedIndexing();
		Main.aceEditor.session.bgTokenizer.start(0);
	}
	public static function runNext():Void {
		var left = --itemsLeft;
		var item = itemQueue.shift();
		var now = Date.now().getTime();
		if (lastLabelUpdateTime < now - 333) {
			lastLabelUpdateTime = now;
			Project.nameNode.innerText = 'Indexing (${itemQueue.length})...';
		}
		if (item != null) {
			runItem(item);
		} else if (left <= 0) {
			runFinish();
		}
	}
	
	private static var jsDoc_full:RegExp = new RegExp("^///\\s*" // start
		+ "\\w*[ \t]*(\\(.+)" // `func(...`
	);
	/** 2.3 only! */
	private static var jsDoc_func:RegExp = new RegExp("^///\\s*" // start
		+ "@func\\s+"
		+ "(\\w+)\\s*" // name -> $1
		+ "\\(" + "(.*)" + "(\\).*)" // args -> $2 (greedy)
	);
	private static var jsDoc_param = new RegExp("^///\\s*"
		+ "@(?:arg|param|argument)\\s+"
		+ "(?:\\{(.*?)\\}\\s*)?" // {type}?
		+ "(\\S+(?:\\s+=.+)?)" // `arg` or `arg=value` -> $1
	);
	private static var jsDoc_hint = new RegExp("^///\\s*"
		+ "@hint\\b\\s*"
		+ "(?:\\{(.+)?\\}\\s*)?" // type -> $1
		+ "(new\\b\\s*)?" // constructor mark -> $2
		+ "(.+)" // the stuff we'll have to parse ourselves
	);
	private static var jsDoc_hint_extimpl = new RegExp("^///\\s*"
		+ "@hint\\b\\s*"
		+ "(\\w+)" // name
		+ "\\b\\s*"
		+ "(extends|implements)"
		+ "\\b\\s*"
		+ "(\\w+)" // name
	);
	private static var jsDoc_self = new RegExp("^///\\s*"
		+ "@(?:self|this)\\b\\s*"
		+ "\\{(\\w+)\\}"
	);
	private static var jsDoc_return = new RegExp("^///\\s*"
		+ "@return(?:s)?\\b\\s*"
		+ "\\{(.*?)\\}"
	);
	
	private static var jsDoc_implements = new RegExp("^///\\s*"
		+ "@implement(?:s)?"
		+ "(?:\\b\\s*\\{(\\w+)\\})?"
	);
	private static var jsDoc_implements_line = new RegExp("^\\s*(\\w+)");
	
	private static var jsDoc_interface = new RegExp("^///\\s*"
		+ "@interface\\b\\s*"
		+ "(?:\\{(\\w+)\\})?"
	);
	
	private static var jsDoc_is = new RegExp("^///\\s*"
		+ "@is(?:s)?"
		+ "\\b\\s*\\{(.+?)\\}"
	);
	private static var jsDoc_is_line = (function() {
		var id = "[_a-zA-Z]\\w*";
		return new RegExp("^\\s*(?:" + [
			'globalvar\\s+($id(?:\\s*,\\s*$id)*)', // globalvar name[, name2]
			'global\\s*\\.\\s*($id)\\s*=', // global.name=
			'($id)\\s*=' // name=
		].join("|") + ")");
	})();
	private static var jsDoc_template = new RegExp("^///\\s*"
		+ "@template\\b\\s*"
		+ "(?:\\{(.*?)\\}\\s*)?"
		+ "(\\S+)"
	);
	
	private static var gmlDoc_full = new RegExp("^\\s*\\w*\\s*\\(.*\\)");
	private static var parseConst_rx10 = new RegExp("^-?\\d+$");
	private static var parseConst_rx16 = new RegExp("^(?:0x|\\$)([0-9a-fA-F]+)$");
	private static var localType = new RegExp("^/\\*[ \t]*:[ \t]*(\\w+)\\*/$");
	private static function parseConst(s:String):Null<Int> {
		var mt = parseConst_rx10.exec(s);
		if (mt != null) return Std.parseInt(s);
		mt = parseConst_rx16.exec(s);
		if (mt != null) return Std.parseInt("0x" + mt[1]);
		return null;
	}
	
	private static var privateFieldRC:RegExpCache = new RegExpCache();
	private static var privateGlobalRC:RegExpCache = new RegExpCache();
	
	public static function runSyncImpl(
		orig:FullPath, src:GmlCode, main:String, out:GmlSeekData, locals:GmlLocals, kind:FileKind
	):Void {
		var mainTop = main;
		var sub = null;
		var q = new GmlReaderExt(src);
		var version:GmlVersion = GmlAPI.version;
		var row = 0;
		var project = Project.current;
		var notLam = !Std.is(kind, KGmlLambdas);
		var canLam = notLam && project.canLambda();
		var canDefineComp = Std.is(kind, KGml) ? (cast kind:KGml).canDefineComp : false;
		var cubDepth:Int = 0; // depth of {}
		var additionalKeywordsMap = version.config.additionalKeywordsMap;
		var hasFunctionLiterals = additionalKeywordsMap.exists("function");
		var hasTryCatch = additionalKeywordsMap.exists("catch");
		var specTypeInst = GmlLinter.getOption((p) -> p.specTypeInst);
		var funcsAreGlobal = GmlFileKindTools.functionsAreGlobal(kind);
		var isObject = Std.is(kind, KGmlEvents);
		var isCreateEvent = isObject && locals.name == "create";
		var __objectName:String = null;
		function getObjectName():String {
			if (__objectName == null) {
				var p = new Path(orig);
				p.dir = null;
				if (p.ext.toLowerCase() == "gmx") { // .object.gmx
					__objectName = Path.withoutExtension(p.file);
				} else __objectName = p.file;
			}
			return __objectName;
		}
		var localKind = notLam ? "local" : "sublocal";
		var subLocalDepth:Null<Int> = null;
		if (project.properties.lambdaMode == Scripts) {
			if (orig.contains("/" + GmlExtLambda.lfPrefix)) {
				canLam = true;
				localKind = "sublocal";
			}
		}
		inline function setLookup(s:String, eol:Bool = false):Void {
			GmlAPI.gmlLookup.set(s, { path: orig, sub: sub, row: row, col: eol ? null : 0 });
			if (s != mainTop) GmlAPI.gmlLookupText += s + "\n";
		}
		if (main != null) setLookup(main);
		/**
		 * A lazy parser.
		 * You tell it what you're looking for, and it reads the input till it finds any of that.
		 */
		function find(flags:GmlSeekerFlags):String {
			while (q.loop) {
				var start = q.pos;
				var c = q.read(), s:String;
				switch (c) {
					case "\r".code: if (flags.has(Line)) return "\n";
					case "\n".code: {
						row += 1;
						if (flags.has(Line)) return "\n";
					};
					case ",".code: if (flags.has(Comma)) return ",";
					case ".".code: if (flags.has(Period)) return ".";
					case ":".code: if (flags.has(Colon)) return ":";
					case ";".code: if (flags.has(Semico)) return ";";
					case "(".code: if (flags.has(Par0)) return "(";
					case ")".code: if (flags.has(Par1)) return ")";
					case "[".code: if (flags.has(Sqb0)) return "[";
					case "]".code: if (flags.has(Sqb1)) return "]";
					case "{".code: {
						cubDepth++;
						if (flags.has(Cub0)) return "{";
					};
					case "}".code: {
						cubDepth--;
						if (subLocalDepth != null && cubDepth <= subLocalDepth) {
							localKind = "local";
							subLocalDepth = null;
						}
						if (flags.has(Cub1)) return "}";
					}
					case "=".code: if (flags.has(SetOp) && q.peek() != "=".code) return "=";
					case "/".code: switch (q.peek()) {
						case "/".code: {
							q.skip();
							q.skipLine();
							if (q.get(start + 2) == "!".code && q.get(start + 3) == "#".code) {
								if (q.substring(start + 4, start + 9) == "mfunc") do {
									//  01234567890
									// `//!#mfunc name
									var c = q.get(start + 9);
									if (!c.isSpace0()) break;
									var line = q.substring(start + 10, q.pos);
									var sp = line.indexOf(" ");
									var name = line.substring(0, sp);
									var json = try {
										haxe.Json.parse(line.substring(sp + 1));
									} catch (_:Dynamic) break;
									var mf = new GmlExtMFunc(name, json);
									setLookup(name);
									out.mfuncs[name] = mf;
									out.comps[name] = mf.comp;
									out.kindList.push(name);
									var tokenType = ace.AceMacro.jsOrx(json.token, "macro.function");
									out.kindMap.set(name, tokenType);
									var mfd = new GmlFuncDoc(name, name + "(", ")", mf.args, false);
									out.docs[name] = mfd;
								} while (false);
							}
							else if (flags.has(Doc) && q.get(start + 2) == "/".code) {
								return q.substring(start, q.pos);
							}
						};
						case "*".code: {
							q.skip();
							row += q.skipComment();
							if (flags.has(ComBlock)) {
								return q.substring(start, q.pos);
							}
						};
						default:
					};
					case '"'.code, "'".code, "`".code, "@".code: row += q.skipStringAuto(c, version);
					case "#".code: {
						q.skipIdent1();
						if (q.pos > start + 1) {
							s = q.substring(start, q.pos);
							switch (s) {
								case "#define","#target": if (flags.has(Define)) {
									if (start == 0) return s;
									c = q.get(start - 1);
									if (c == "\r".code || c == "\n".code) {
										return s;
									}
								};
								case "#region", "#endregion": q.skipLine();
								case "#macro": if (flags.has(Macro)) return s;
								default:
							}
						}
					};
					case "$".code: { // hex literal
						while (q.loopLocal) {
							c = q.peek();
							if (c.isHex()) q.skip();  else break;
						}
					};
					default: {
						if (c.isIdent0()) {
							q.skipIdent1();
							var id = q.substring(start, q.pos);
							var m = ace.AceMacro.jsOrx(out.macros[id], GmlAPI.gmlMacros[id]);
							if (m != null) {
								if (q.depth < 16) {
									q.pushSource(m.expr);
									return find(flags);
								} else return null;
							} else if (flags.has(Ident)) switch (id) {
								case "let", "const":
									// unfortunately there is no warranty that we'll index
									// let/const macros before we index other files, so let's just
									// assume that `let <ident>` means that you have such a macro.
									var k = q.pos;
									while (q.loopLocal) {
										c = q.get(k);
										if (c.isSpace1()) k++; else break;
									}
									c = q.get(k);
									if (c.isIdent0()) id = "var";
							}
							if (hasFunctionLiterals && flags.has(Define) && id == "function") return id;
							if (flags.has(Static) && id == "static") return id;
							if (flags.has(Ident)) return id;
						} else if (c.isDigit()) {
							if (q.peek() == "x".code) {
								q.skip();
								while (q.loopLocal) {
									c = q.peek();
									if (c.isHex()) q.skip();  else break;
								}
							} else {
								var seenDot = false;
								while (q.loopLocal) {
									c = q.peek();
									if (c == ".".code) {
										if (!seenDot) {
											seenDot = true;
											q.skip();
										} else break;
									} else if (c.isDigit()) {
										q.skip();
									} else break;
								}
							}
						}
					};
				}
			}
			return null;
		} // find
		var mainComp:AceAutoCompleteItem = main != null ? GmlAPI.gmlAssetComp[main] : null;
		var s:String, name:String, start:Int = 0;
		var doc:GmlFuncDoc = null;
		var docIsAutoFunc = false;
		var jsDocArgs:Array<String> = null;
		var jsDocTypes:Array<String> = null;
		var jsDocRest:Bool = false;
		var jsDocSelf:String = null;
		var jsDocReturn:String = null;
		var jsDocInterface:Bool = false;
		var jsDocInterfaceName:String = null;
		var jsDocImplements:Array<String> = null;
		var jsDocTemplateItems:Array<GmlTypeTemplateItem> = null;
		
		function jsDocTypesFlush(?pre:Array<GmlTypeTemplateItem>):Array<GmlType> {
			var tpl = pre != null && jsDocTemplateItems != null
				? pre.concat(jsDocTemplateItems)
				: JsTools.or(pre, jsDocTemplateItems);
			var rt = [];
			if (tpl != null) {
				for (s in jsDocTypes) {
					s = GmlTypeTools.patchTemplateItems(s, tpl);
					rt.push(GmlTypeDef.parse(s));
				}
			} else for (s in jsDocTypes) rt.push(GmlTypeDef.parse(s));
			return rt;
		}
		/**  */
		inline function linkDoc():Void {
			if (doc != null) out.docs[main] = doc;
		}
		inline function resetDoc():Void {
			jsDocArgs = null;
			jsDocTypes = null;
			jsDocRest = null;
			jsDocSelf = null;
			jsDocReturn = null;
			jsDocInterface = false;
			jsDocInterfaceName = null;
			jsDocImplements = null;
			jsDocTemplateItems = null;
		}
		function flushDoc():Void {
			var updateComp = false;
			if (doc == null && (main != null && main != "")) {
				// no doc yet, but there should be, so let's scrap what we may
				doc = out.docs[main];
				if (doc == null) {
					doc = GmlFuncDoc.create(main);
					linkDoc();
				}
				updateComp = true;
			}
			if (doc != null) {
				if (jsDocArgs != null) {
					doc.args = jsDocArgs;
					doc.argTypes = jsDocTypesFlush();
					doc.templateItems = jsDocTemplateItems;
					if (jsDocRest) doc.rest = jsDocRest;
					doc.procHasReturn(src, start, q.pos, docIsAutoFunc);
				} else if (doc.args.length != 0 || doc.hasReturn) {
					// have some arguments and no JSDoc
					doc.procHasReturn(src, start, q.pos, docIsAutoFunc, doc.args);
				} else { // no JSDoc, try indexing
					doc.fromCode(src, start, q.pos);
					updateComp = true;
				}
				if (jsDocReturn != null) {
					doc.returnTypeString = jsDocReturn;
					updateComp = true;
				}
				if (jsDocInterface) {
					if (jsDocInterfaceName == null) jsDocInterfaceName = main;
					if (!out.namespaceHints.exists(jsDocInterfaceName)) {
						out.namespaceHints[jsDocInterfaceName] = new GmlSeekDataNamespaceHint(jsDocInterfaceName, null, null);
					}
				}
				doc.selfType = GmlTypeDef.parse(jsDocSelf);
				
				//
				if (updateComp && mainComp != null) mainComp.doc = doc.getAcText();
			}
			if (jsDocImplements != null) {
				var ownType:String;
				if (isObject) {
					ownType = getObjectName();
				} else ownType = main;
				//
				var arr = out.namespaceImplements[ownType];
				if (arr == null) { arr = []; out.namespaceImplements[ownType] = arr; }
				//
				if (ownType == null) {
					Main.console.warn("Trying to add @implements without a known self-type", arr);
				} else for (nsi in jsDocImplements) {
					if (arr.indexOf(nsi) < 0) arr.push(nsi);
				}
			}
			doc = null;
			docIsAutoFunc = false;
			resetDoc();
		}
		function procLambdaIdent(s:GmlName, locals:GmlLocals):Void {
			var seekData = GmlExtLambda.seekData;
			var lfLocals = seekData.locals[s];
			if (lfLocals == null && project.properties.lambdaMode == Scripts) {
				//
				var rel = 'scripts/$s/$s.gml';
				var full = project.fullPath(rel);
				var lgml = try {
					project.readTextFileSync(rel);
				} catch (_:Dynamic) null;
				if (lgml == null) {
					Main.console.warn("Lambda missing: " + s);
					lgml = "";
				}
				//
				runSync(full, lgml, "", KGmlLambdas.inst);
				var d = GmlSeekData.map[full];
				if (d == null) {
					Main.console.warn("We just asked to index a lambda script and it's not there..?");
					lfLocals = new GmlLocals(s);
				} else lfLocals = d.locals[""];
				seekData.locals.set(s, lfLocals);
			}
			if (lfLocals != null) locals.addLocals(lfLocals);
		}
		//
		var q_swap:GmlReaderExt = null;
		inline function q_store():Void {
			if (q_swap == null) q_swap = new GmlReaderExt(src);
			q_swap.setTo(q);
		}
		inline function q_restore():Void {
			q.setTo(q_swap);
		}
		function procFuncLiteralRetArrow() {
			if (q.loop) {
				var orig = q.pos;
				q.skipSpaces1_local();
				if (q.substr(q.pos, 4) == "/*->") {
					q.pos += 4;
					var typeStart = q.pos;
					q.skipComment();
					var typeEnd = q.pos - 2;
					q.pos = typeStart;
					if (q.skipType(typeEnd)) {
						jsDocReturn = q.substring(typeStart, q.pos);
					} else q.pos = orig;
				} else q.pos = orig;
			}
		}
		function procFuncLiteralArgs() {
			if (find(Par0) == "(") {
				while (q.loop) {
					var s = find(Ident | Par1);
					if (s == ")" || s == null) break;
					locals.add(s, localKind);
				}
				procFuncLiteralRetArrow();
			}
		}
		//
		var privateFieldRegex = privateFieldRC.update(project.properties.privateFieldRegex);
		var privateGlobalRegex = privateGlobalRC.update(project.properties.privateGlobalRegex);
		//
		var addFieldHint_doc:GmlFuncDoc = null;
		function addFieldHint(isConstructor:Bool, namespace:String, isInst:Bool, field:String,
		args:String, info:String, type:GmlType, argTypes:Array<GmlType>, isAuto:Bool) {
			var parentSpace:String = null;
			if (namespace == null) {
				if (isCreateEvent) {
					namespace = getObjectName();
					parentSpace = project.objectParents[namespace];
				} else if (doc != null) {
					namespace = doc.name;
					parentSpace = doc.parentName;
					if (namespace == null) return;
				} else return;
			}
			field = JsTools.or(field, "");
				
			var isField = (field != "");
			var name = isField ? field : namespace;
			
			var hintDoc:GmlFuncDoc = null;
			if (args != null) {
				var fa = name + GmlFuncDoc.patchArrow(args);
				hintDoc = GmlFuncDoc.parse(fa);
				hintDoc.trimArgs();
				hintDoc.isConstructor = isConstructor;
				if (argTypes != null) hintDoc.argTypes = argTypes;
				if (type == null) type = hintDoc.getFunctionType();
				info = NativeString.nzcct(hintDoc.getAcText(), "\n", info);
			}
			addFieldHint_doc = hintDoc;
			info = NativeString.nzcct(info, "\n", 'from $namespace');
			if (type != null) info = NativeString.nzcct(info, "\n", "type " + type.toString());
			
			var compMeta = isField ? (args != null ? "function" : "variable") : "namespace";
			var comp = privateFieldRegex == null || !privateFieldRegex.test(s)
				? new AceAutoCompleteItem(name, compMeta, info) : null;
			var hint = new GmlSeekDataHint(namespace, isInst, field, comp, hintDoc, parentSpace, type);
			
			var lastHint = out.fieldHints[hint.key];
			if (lastHint == null) {
				out.fieldHints[hint.key] = hint;
			} else lastHint.merge(hint, isAuto);
			
			if (isField) {
				//
			} else if (!isInst) {
				out.comps[name] = comp;
				//
				if (!out.kindMap.exists(name)) out.kindList.push(name);
				out.kindMap[name] = "namespace";
				if (hintDoc != null) out.docs[name] = hintDoc;
			}
		}
		function addInstVar(s:String):Void {
			if (out.instFieldMap[s] == null
				&& (privateFieldRegex == null || !privateFieldRegex.test(s))
			) {
				var fd = GmlAPI.gmlInstFieldMap[s];
				if (fd == null) {
					fd = new GmlField(s, "variable");
					GmlAPI.gmlInstFieldMap.set(s, fd);
				}
				out.instFieldList.push(fd);
				out.instFieldMap.set(s, fd);
				out.instFieldComp.push(fd.comp);
			}
		}
		function doLoop(?exitAtCubDepth:Int) {
			//var oldPos = q.pos, oldSource = q.source;
		while (q.loop) {
			/*//
			if (q.pos < oldPos && debug) {
				Main.console.warn("old", oldPos, oldSource.length);
				Main.console.warn("new", q.pos, q.source.length, q.source == oldSource);
			}
			oldPos = q.pos;
			oldSource = q.source;
			//*/
			var p:Int, flags:Int;
			var c:CharCode, mt:RegExpMatch;
			flags = Ident | Doc | Define | Macro;
			if (exitAtCubDepth != null || funcsAreGlobal) flags |= Cub1;
			s = find(flags);
			if (s == null) continue;
			if (s.fastCodeAt(0) == "/".code) { // JSDoc
				/*
				 * A thing to remember! Suppose you have the following:
				 * ```
				 * function a() {}
				 * /// hello!
				 * function b() {}
				 * ```
				 * for that comment, `main` would not be `b` since we didn't get to `b` yet
				 */
				mt = jsDoc_implements.exec(s);
				if (mt != null) {
					var nsi = mt[1];
					if (nsi == null) {
						var lineStart = q.source.lastIndexOf("\n", q.pos - 1) + 1;
						var lineText = q.source.substring(lineStart, q.pos);
						var lineMatch = jsDoc_implements_line.exec(lineText);
						if (lineMatch == null) continue;
						nsi = lineMatch[1];
					}
					if (jsDocImplements == null) jsDocImplements = [];
					jsDocImplements.push(nsi);
					continue;
				}
				
				mt = jsDoc_is.exec(s);
				if (mt != null) {
					var typeStr = mt[1];
					var lineStart = q.source.lastIndexOf("\n", q.pos - 1) + 1;
					var lineText = q.source.substring(lineStart, q.pos);
					var lineMatch = jsDoc_is_line.exec(lineText);
					if (lineMatch == null) continue;
					var kind = lineMatch[1];
					var name:String;
					var type = GmlTypeDef.parse(typeStr);
					if (lineMatch[1] != null) {
						tools.RegExpTools.each(JsTools.rx(~/\w+/g), lineMatch[1], function(mt) {
							name = mt[0];
							out.globalVarTypes[name] = type;
							var comp = out.comps[name];
							if (comp != null) comp.setDocTag("type", typeStr);
						});
					} else if (lineMatch[2] != null) {
						name = lineMatch[2];
						out.globalTypes[name] = type;
						var globalField = out.globalFields[name];
						if (globalField != null && globalField.comp != null) {
							globalField.comp.setDocTag("type", typeStr);
						}
					} else {
						name = lineMatch[3];
						var namespace:String;
						if (isCreateEvent) {
							namespace = getObjectName();
						} else if (doc != null) {
							namespace = doc.name;
							if (namespace == null) continue;
						} else continue;
						var hint = out.fieldHints[namespace + ":" + name];
						if (hint != null) {
							hint.type = type;
							if (hint.comp != null) hint.comp.setDocTag("type", typeStr);
						}
					}
					continue;
				}
				
				mt = jsDoc_template.exec(s);
				if (mt != null) {
					var tc = mt[1];
					var names = mt[2];
					if (jsDocTemplateItems == null) jsDocTemplateItems = [];
					for (name in names.split(",")) {
						jsDocTemplateItems.push(new GmlTypeTemplateItem(name, tc));
					}
					continue;
				}
				
				mt = jsDoc_hint_extimpl.exec(s);
				if (mt != null) {
					var name = mt[1];
					var target = mt[3];
					if (mt[2] == "implements") {
						var arr = out.namespaceImplements[name];
						if (arr == null) out.namespaceImplements[name] = arr = [];
						if (arr.indexOf(target) < 0) arr.push(target);
					} else {
						var imp = out.namespaceHints[name];
						if (imp != null) {
							imp.parentSpace = target;
						} else {
							imp = new GmlSeekDataNamespaceHint(name, target, null);
							out.namespaceHints[name] = imp;
						}
					}
					continue;
				}
				
				mt = jsDoc_hint.exec(s);
				if (mt != null) { // @hint
					var mti = 0;
					var typeStr = mt[1];
					var isNew = mt[2] != null;
					var hr = new GmlReader(mt[3], version), hp:Int;
					hr.skipSpaces0_local();
					
					var templateSelf:GmlType = null;
					var templateItems:Array<GmlTypeTemplateItem> = null;
					var nsName = hr.readIdent();
					var ctrReturn = null;
					if (nsName != null) {
						if (isNew) ctrReturn = nsName;
						hr.skipSpaces0_local();
						if (hr.peek() == "<".code) { // namespace<params>
							hp = hr.pos;
							if (hr.skipTypeParams()) {
								templateItems = GmlTypeTemplateItem.parseSplit(hr.substring(hp + 1, hr.pos - 1));
								if (isNew) ctrReturn += GmlTypeTemplateItem.joinTemplateString(templateItems, false);
								templateSelf = GmlTypeTemplateItem.toTemplateSelf(templateItems);
								hr.skipSpaces0_local();
							} else continue;
						}
					}
					
					if (nsName == null && doc != null && doc.templateItems != null) {
						templateSelf = GmlTypeTemplateItem.toTemplateSelf(doc.templateItems);
						templateItems = doc.templateItems.copy();
					}
					if (templateItems != null && typeStr != null) {
						typeStr = GmlTypeTools.patchTemplateItems(typeStr, templateItems);
					}
					
					var isInst = false;
					var fdName = null;
					var c = hr.peek();
					if (c == ".".code || c == ":".code) {
						isInst = c == ":".code;
						if (!isInst) templateSelf = null;
						hr.skip();
						hr.skipSpaces0_local();
						fdName = hr.readIdent();
						if (fdName != null) {
							hr.skipSpaces0_local();
							if (hr.peek() == "<".code) { // namespace<params>
								hp = hr.pos;
								if (hr.skipTypeParams()) {
									var fdp = GmlTypeTemplateItem.parseSplit(hr.substring(hp + 1, hr.pos - 1));
									templateItems = templateItems.nzcct(fdp);
									hr.skipSpaces0_local();
								} else continue;
							}
						}
					}
					
					var args = null;
					if (hr.peek() == "(".code) {
						hp = hr.pos;
						hr.skip();
						var depth = 1;
						while (hr.loopLocal) {
							c = hr.read();
							switch (c) {
								case "(".code: depth++;
								case ")".code: if (--depth <= 0) break;
							}
						}
						if (depth > 0) continue;
						if (hr.peekstr(2) == "->") {
							hr.skip(2);
							hr.skipType();
						}
						args = hr.substring(hp, hr.pos);
						if (templateItems != null) {
							args = GmlTypeTools.patchTemplateItems(args, templateItems);
						}
						hr.skipSpaces0_local();
					}
					
					var info = hr.source.substring(hr.pos);
					
					addFieldHint(isNew, nsName, isInst, fdName, args, info, GmlTypeDef.parse(typeStr), null, false);
					if (addFieldHint_doc != null) {
						if (ctrReturn != null) addFieldHint_doc.returnTypeString = ctrReturn;
						if (templateSelf != null) addFieldHint_doc.templateSelf = templateSelf;
						if (templateItems != null) addFieldHint_doc.templateItems = templateItems;
					}
					continue; // found!
				}
				
				mt = jsDoc_self.exec(s);
				if (mt != null) {
					jsDocSelf = mt[1];
					continue;
				}
				
				mt = jsDoc_return.exec(s);
				if (mt != null) {
					jsDocReturn = mt[1];
					continue;
				}
				
				mt = jsDoc_interface.exec(s);
				if (mt != null) {
					jsDocInterface = true;
					jsDocInterfaceName = mt[1];
					if (jsDocInterfaceName == null) {
						if (isObject) {
							jsDocInterfaceName = getObjectName();
						} else if (!hasFunctionLiterals) {
							jsDocInterfaceName = main;
						}
					}
					continue;
				}
				
				mt = jsDoc_param.exec(s);
				if (mt != null) {
					if (jsDocArgs == null) {
						jsDocArgs = [];
						jsDocTypes = [];
					}
					var argText = mt[2];
					var argType = mt[1];
					for (arg in argText.split(",")) {
						jsDocArgs.push(arg);
						jsDocTypes.push(argType);
						if (arg.contains("...")) jsDocRest = true;
					}
					continue; // found!
				}
				
				if (hasFunctionLiterals) {
					mt = jsDoc_func.exec(s);
					if (mt != null) { // 2.3 @func
						var fn = mt[1];
						var fa = mt[2];
						var pre = fn + "(";
						var post = mt[3];
						var rest = fa.contains("...");
						var jsd = new GmlFuncDoc(fn, pre, post, fa.splitNonEmpty(","), rest);
						out.docs[fn] = jsd;
						out.comps[fn] = new AceAutoCompleteItem(fn, pre + fa + post);
						if (!out.kindMap.exists(fn)) {
							out.kindMap[fn] = "asset.script";
							out.kindList.push(fn);
						}
						setLookup(fn);
						continue;
					}
				}
				
				// tags from hereafter have no meaning outside of a script/function
				if (main == null) continue;
				
				// Classic JSDoc (`/// func(arg1, arg2)`) ?:
				mt = jsDoc_full.exec(s);
				if (mt != null) {
					if (!out.docs.exists(main)) {
						doc = GmlFuncDoc.parse(main + mt[1]);
						linkDoc();
						if (mainComp != null && mainComp.doc == null) {
							mainComp.doc = s;
						}
					}
					continue; // found!
				}
				
				// merge suffix-docs in GML variants with #define args into the doc line:
				if (version.hasScriptArgs()) {
					// `#define func(a, b)\n/// does things` -> `func(a, b) does things`
					s = s.substring(3).trimLeft();
					doc = out.docs[main];
					if (doc == null) {
						if (gmlDoc_full.test(s)) {
							doc = GmlFuncDoc.parse(s);
							doc.name = main;
							doc.pre = main + "(";
						} else doc = GmlFuncDoc.createRest(main);
						linkDoc();
					} else {
						if (gmlDoc_full.test(s)) {
							GmlFuncDoc.parse(s, doc);
							doc.name = main;
							doc.pre = main + "(";
						} else doc.post += " " + s;
					}
					mainComp.doc = doc.getAcText();
					continue; // found!
				}
				
				// perhaps it's just extra text
				s = s.substring(3).trimBoth();
				if (mainComp != null) mainComp.doc = mainComp.doc.nzcct("\n", s);
				continue;
			}
			// (known to not be JSDoc from hereafter):
			switch (s) {
				case "}": {
					if (cubDepth <= 0 && funcsAreGlobal && docIsAutoFunc) {
						flushDoc();
						main = null;
					}
					if (exitAtCubDepth != null && cubDepth <= exitAtCubDepth) return;
				};
				case "#define", "#target", "function": {
					// we don't have to worry about #event/etc because they
					// do not occur in files themselves
					var isDefine = (s == "#define");
					var isFunc = (s == "function");
					if (isFunc && funcsAreGlobal && cubDepth == 0) isDefine = true;
					
					var fname:String;
					if (isFunc) {
						q.skipSpaces0();
						if (q.peek().isIdent0_ni()) {
							p = q.pos;
							q.skipIdent1();
							fname = q.substring(p, q.pos);
						} else fname = null;
					} else fname = find(Ident);
					
					// early exit if it's a `x = function()` or a function-in-function
					if (isFunc && (!isDefine || fname == null)) {
						if (cubDepth > 0 || !funcsAreGlobal) {
							if (!funcsAreGlobal && cubDepth == 0 && fname != null) {
								// function name() in events
								addInstVar(fname);
							}
							subLocalDepth = cubDepth;
							localKind = "sublocal";
						}
						if (isCreateEvent && cubDepth == 0 && fname != null) {
							var argsStart = q.pos;
							procFuncLiteralArgs();
							var args:String = q.substring(argsStart, q.pos).trimBoth();
							var argTypes = null;
							if (jsDocArgs != null) {
								args = "(" + jsDocArgs.join(", ") + ")";
								argTypes = jsDocTypesFlush();
								jsDocArgs = null;
								jsDocTypes = null;
							}
							if (jsDocReturn != null) {
								args += GmlFuncDoc.retArrow + jsDocReturn;
								jsDocReturn = null;
							}
							//
							s = find(Line | Cub0 | Ident | Colon);
							var isConstructor = (s == ":" || s == "constructor");
							//
							addFieldHint(isConstructor, getObjectName(), true, fname, args, null, null, argTypes, true);
						} else procFuncLiteralArgs();
						resetDoc(); // discard any collected JSDoc
						continue;
					}
					
					if (isFunc) {
						// soft flush so that JSDocs prior to declaration can apply
						doc = null;
						docIsAutoFunc = false;
					} else flushDoc();
					main = fname;
					if (jsDocInterface && jsDocInterfaceName == null) {
						jsDocInterfaceName = main;
					}
					start = q.pos;
					sub = main;
					row = isFunc ? -1 : 0;
					setLookup(main, true);
					locals = new GmlLocals(main);
					out.locals.set(main, locals);
					if (isFunc || isDefine && version.hasScriptArgs()) { // `<keyword> name(...args)`
						s = find(isFunc ? Par0 : Line | Par0);
						if (s == "(") {
							var openPos = q.pos;
							flags = Ident | Par1 | (isFunc ? 0 : Line);
							var foundArg = false;
							while (q.loop) {
								s = find(flags);
								if (s == ")" || s == "\n" || s == null) break;
								locals.add(s, localKind);
								foundArg = true;
							}
							if (isDefine && jsDocArgs != null) {
								// `@param` override the parsed arguments
								doc = GmlFuncDoc.create(main, jsDocArgs, jsDocRest);
								doc.argTypes = jsDocTypesFlush();
								jsDocArgs = null;
								jsDocTypes = null;
								jsDocRest = false;
							} else {
								var docStart = main;
								if (jsDocTemplateItems != null) {
									docStart += GmlTypeTemplateItem.joinTemplateString(jsDocTemplateItems, true);
								}
								doc = GmlFuncDoc.parse(docStart + q.substring(start, q.pos));
								doc.trimArgs();
							}
							procFuncLiteralRetArrow();
							if (jsDocReturn != null) {
								doc.returnTypeString = jsDocReturn;
								jsDocReturn = null;
							}
							doc.templateItems = jsDocTemplateItems;
							jsDocTemplateItems = null;
							docIsAutoFunc = isFunc;
							linkDoc();
						}
					}
					//
					if (isDefine && canDefineComp) {
						mainComp = new AceAutoCompleteItem(main, "script", doc != null 
							? doc.getAcText()
							: (q.pos > start ? main + q.substring(start, q.pos) : null)
						);
						out.comps[main] = mainComp;
						out.kindList.push(main);
						out.kindMap.set(main, "asset.script");
					}
					//
					if (isFunc) {
						s = find(Line | Cub0 | Ident | Colon);
						if (s == ":" || s == "constructor") { // function A(a, b) : B(a, b) constructor
							if (doc == null) {
								doc = GmlFuncDoc.create(main);
								linkDoc();
							}
							doc.isConstructor = true;
							doc.returnTypeString = doc.getConstructorType();
							if (s == ":") {
								s = find(Line | Cub0 | Ident);
								if (s != null && (s.fastCodeAt(0):CharCode).isIdent0_ni()) {
									doc.parentName = s;
								}
							}
							out.namespaceHints[main] = new GmlSeekDataNamespaceHint(main, doc.parentName, false);
						}
					}
				};
				case "#macro": {
					q.skipSpaces0();
					c = q.peek(); if (!c.isIdent0()) continue;
					p = q.pos;
					q.skipIdent1();
					name = q.substring(p, q.pos);
					// `#macro Config:name`?
					var cfg:String;
					if (q.peek() == ":".code) {
						q.skip();
						c = q.peek();
						if (c.isIdent0()) {
							p = q.pos;
							q.skipIdent1();
							cfg = name;
							name = q.substring(p, q.pos);
						} else cfg = null;
					} else cfg = null;
					q.skipSpaces0();
					// value:
					p = q.pos;
					s = "";
					do {
						q.skipLine();
						if (q.peek( -1) == "\\".code) {
							s += q.substring(p, q.pos - 1) + "\n";
							q.skipLineEnd();
							p = q.pos;
							row += 1;
						} else break;
					} while (q.loopLocal);
					s += q.substring(p, q.pos);
					// we don't currently support configuration nesting
					if (cfg == null || cfg == project.config) {
						var m = new GmlMacro(name, orig, s, cfg);
						if (out.macros.exists(name)) {
							out.comps.remove(name);
						} else {
							out.kindList.push(name);
							if (GmlAPI.stdKind[m.expr] == "keyword") {
								// keyword forwarding
								out.kindMap[name] = "keyword";
							} else {
								out.kindMap[name] = "macro";
							}
						}
						//
						var i = name.indexOf("_mf");
						if (i < 0 || !out.mfuncs.exists(name.substring(0, i))) {
							out.comps[name] = m.comp;
							setLookup(name, true);
						} else {
							// adjust for mfunc rows being hidden
							row -= 1;
						}
						//
						out.macros[name] = m;
					}
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
					name = find(Ident);
					locals.add(name, localKind, "try-catch");
				};
				case "var": {
					while (q.loop) {
						name = find(Ident);
						if (name == null) break;
						if (name == "var") { // `var var`
							name = find(Ident);
						} else if (GmlAPI.kwFlow[name]) {
							// might eat a structure but that code's broken anyway
							break;
						}
						locals.add(name, localKind);
						q_store();
						flags = SetOp | Comma | Semico | Ident | ComBlock;
						s = find(flags);
						if (s != null && s.startsWith("/*")) { // name/*...*/
							mt = localType.exec(s);
							if (mt != null) {
								//locals.type.set(name, mt[1]);
							}
							s = find(flags);
						}
						if (s == ",") {
							// OK, next
						} else if (s == "=") {
							// name = (balanced expression)[,;]
							var depth = 0;
							var exit = false;
							while (q.loop) {
								q_store();
								s = find(Par0 | Par1 | Sqb0 | Sqb1 | Cub0 | Cub1
									| Comma | Semico | Ident);
								// EOF:
								if (s == null) {
									exit = true;
									break;
								}
								switch (s) {
									case "(", "[", "{": depth += 1;
									case ")", "]", "}": {
										depth -= 1;
										if (depth < 0) {
											q.pos--;
											break;
										}
									};
									case ",": if (depth == 0) break;
									case ";": exit = true; break;
									default: { // ident
										if (hasFunctionLiterals && s == "function") {
											var oldLocalKind = localKind;
											if (cubDepth > 0 || !funcsAreGlobal) {
												localKind = "sublocal";
											}
											procFuncLiteralArgs();
											doLoop(cubDepth);
											localKind = oldLocalKind;
										} else if (GmlAPI.kwFlow[s]) {
											q_restore();
											exit = true;
											break;
										} else if (canLam && s.startsWith(GmlExtLambda.lfPrefix)) {
											procLambdaIdent(s, locals);
											continue;
										}
									};
								}
							}
							if (exit) break;
						} else {
							// EOF or `var name something_else`
							q_restore();
							break;
						}
					}
				};
				case "enum": {
					name = find(Ident);
					if (name == null) continue;
					if (find(Cub0) == null) continue;
					var en = new GmlEnum(name, orig);
					out.enums[name] = en;
					out.comps[name] = new AceAutoCompleteItem(name, "enum");
					setLookup(name);
					var nextVal:Null<Int> = 0;
					while (q.loop) {
						s = find(Ident | Cub1);
						if (s == null || s == "}") break;
						en.lastItem = s;
						en.names.push(s);
						en.items.set(s, true);
						var ac = new AceAutoCompleteItem(name + "." + s, "enum");
						var acf = new AceAutoCompleteItem(s, "enum");
						en.compList.push(ac);
						en.fieldComp.push(acf);
						en.compMap.set(s, ac);
						en.fieldLookup.set(s, { path: orig, sub: sub, row: row, col: 0, });
						s = find(Comma | SetOp | Cub1);
						if (s == "=") {
							//
							var doc = null;
							var vp = q.pos;
							while (vp < q.length) {
								var c = q.get(vp++);
								switch (c) {
									case "\r".code, "\n".code: break;
									case "/".code if (q.get(vp) == "/".code): {
										var docStart = ++vp;
										while (vp < q.length) {
											c = q.get(vp);
											if (c == "\r".code || c == "\n".code) break;
											vp++;
										}
										doc = q.substring(docStart, vp).trimBoth();
									};
								}
							}
							//
							vp = q.pos;
							s = find(Comma | Cub1);
							var val = parseConst(q.substring(vp, q.pos - 1).trimBoth());
							if (val != null) {
								acf.doc = ac.doc = "" + val;
								nextVal = val + 1;
							} else nextVal = null;
							if (doc != null) {
								acf.doc = acf.doc != null ? acf.doc + "\t" + doc : doc;
								ac.doc = acf.doc;
							}
						} else if (nextVal != null) {
							acf.doc = ac.doc = "" + (nextVal++);
						}
						if (s == null || s == "}") break;
					}
				};
				default: { // maybe an instance field assignment
					// skip if it's a local/project/extension identifier:
					var isDotSelf = false;
					var isDot = false; {
						var dp = q.pos - s.length;
						while (--dp >= 0) {
							var c = q.get(dp);
							if (c == ".".code) {
								isDot = true;
								while (--dp >= 0) {
									c = q.get(dp);
									if (!c.isSpace1()) break;
								}
								if (c == "f".code
									&& dp >= 3 && q.substr(dp - 3, 4) == "self"
									&& (dp == 3 || !q.get(dp - 4).isIdent1_ni())
								) isDotSelf = true;
							} else if (c.isSpace1()) {
								// OK
							} else break;
						}
					}
					if (!isDot) {
						if (locals.kind[s] != null) continue;
						if (canLam && s.startsWith(GmlExtLambda.lfPrefix)) {
							procLambdaIdent(s, locals);
							continue;
						}
						if (s == "with") {
							locals.hasWith = true;
							continue;
						}
						if (GmlAPI.gmlKind[s] != null || GmlAPI.extKind[s] != null) continue;
					}
					
					// we'll hint top-level variable assignments in constructors and Create events:
					var isConstructorField:Bool;
					if (!isDot || isDotSelf) {
						if (jsDocInterface) {
							var wantDepth = hasFunctionLiterals && funcsAreGlobal ? 1 : 0;
							isConstructorField = (cubDepth == wantDepth);
						} else if (isCreateEvent) {
							isConstructorField = cubDepth == 0;
						} else {
							isConstructorField = cubDepth == 1 && doc != null && doc.isConstructor;
						}
					} else isConstructorField = false;
					
					// skip if we don't have anything to do:
					var kind = GmlAPI.stdKind[s];
					var addInstField:Bool;
					if (kind != null) {
						var ns = GmlAPI.gmlNamespaces[s];
						addInstField = ns == null || ns.noTypeRef;
					} else addInstField = true;
					
					if (!addInstField && (
						// create events shouldn't hint built-ins since we'll auto-include them:
						isCreateEvent
						// other code also shouldn't hint built-ins:
						|| !isConstructorField
						// structs are allowed to override built-in variables specifically:
						|| kind != "variable"
					)) continue;
					
					// skip unless it's `some =` (and no `some ==`)
					var skip = false;
					q_store();
					while (q.loop) switch (q.read()) {
						case " ".code, "\t".code, "\r".code, "\n".code: { };
						case "=".code: skip = q.peek() == "=".code; break;
						case ":".code: {
							var k = q_swap.pos;
							skip = true;
							while (k > 0) {
								var c = q_swap.get(k - 1);
								if (c.isIdent1()) k--; else break;
							}
							while (--k >= 0) switch (q_swap.get(k)) {
								case " ".code, "\t".code, "\r".code, "\n".code: { };
								case ",".code, "{".code: skip = false; break;
								default: break;
							}
							break;
						};
						default: skip = true; break;
					}
					if (skip) { q_restore(); continue; }
					
					// that's an instance variable then
					if (addInstField) addInstVar(s);
					
					//
					if (isConstructorField) {
						q.skipSpaces1();
						var args:String = null;
						var argTypes:Array<GmlType> = null;
						var isConstructor = false;
						var templateSelf:GmlType = null;
						var templateItems:Array<GmlTypeTemplateItem> = null;
						var fieldType:GmlType = null;
						do {
							var c = q.peek();
							switch (c) {
								case "[".code:
									if (specTypeInst) fieldType = GmlTypeDef.anyArray;
									continue;
								case '"'.code:
									if (specTypeInst) fieldType = GmlTypeDef.string;
									continue;
								case "'".code if (!version.hasLiteralStrings()):
									if (specTypeInst) fieldType = GmlTypeDef.string;
									continue;
								case "@".code if (version.hasLiteralStrings() && (
									q.peek(1) == '"'.code || q.peek(1) == "'".code
								)):
									if (specTypeInst) fieldType = GmlTypeDef.string;
									continue;
								case "-".code, "+".code:
									if (specTypeInst) fieldType = GmlTypeDef.number;
									continue;
								case _ if (c.isDigit()):
									if (specTypeInst) fieldType = GmlTypeDef.number;
									continue;
								case _ if (c.isIdent0()):
									// OK!
								default: continue;
							}
							if (!c.isIdent0_ni()) continue;
							var start = q.pos;
							q.skipIdent1();
							var ident = q.substring(start, q.pos);
							switch (ident) {
								case "function":
									// OK!
								case "new" if (hasFunctionLiterals):
									if (specTypeInst) {
										q.skipSpaces1();
										var ctr = q.readIdent();
										if (ctr != null) fieldType = GmlTypeDef.simple(ctr);
									}
									continue;
								case "true", "false":
									if (specTypeInst) fieldType = GmlTypeDef.bool;
									continue;
								default:
									if (specTypeInst) {
										var doc = GmlAPI.stdDoc[ident];
										q.skipSpaces1_local();
										if (doc != null) {
											if (q.peek() == "(".code) {
												fieldType = doc.returnType.mapTemplateTypes([]);
											}
										} else switch (q.peek()) {
											case "\r".code, "\n".code, ";".code:
												fieldType = GmlAPI.stdTypes[ident];
											default:
										}
									}
									continue;
							}
							q.skipSpaces1();
							if (q.peek().isIdent0_ni()) {
								// though you've messed up if you did `static name = function name`
								start = q.pos;
								q.skipIdent1();
								q.skipSpaces1();
							}
							
							start = q.pos;
							if (q.read() != "(".code) continue;
							while (q.loop) {
								var c = q.peek();
								if (c == ")".code) {
									q.skip();
									break;
								} else {
									if (q.skipCommon() < 0) q.skip();
								}
							}
							
							if (jsDocArgs != null) {
								args = "(" + jsDocArgs.join(", ") + ")";
								argTypes = jsDocTypesFlush(JsTools.nca(doc, doc.templateItems));
								jsDocArgs = null;
								jsDocTypes = null;
							} else args = q.substring(start, q.pos);
							
							if (q.peekstr(4) == "/*->") {
								var p = q.pos + 2;
								q.skip(4);
								q.skipComment();
								if (q.peekstr(2, -2) == "*/") {
									args += q.substring(p, q.pos - 2);
								}
							}
							//
							templateItems = jsDocTemplateItems;
							jsDocTemplateItems = null;
							if (doc != null && doc.templateItems != null) {
								templateSelf = GmlTypeTemplateItem.toTemplateSelf(doc.templateItems);
								templateItems = templateItems != null
									? doc.templateItems.concat(templateItems)
									: doc.templateItems.copy();
							}
							
							if (jsDocReturn != null) {
								args += GmlFuncDoc.retArrow + jsDocReturn;
								jsDocReturn = null;
							}
							
							// constructor?:
							q.skipSpaces1();
							if (q.peek() == ":".code) {
								isConstructor = true;
							} else if (q.peek() == "c".code) {
								var ctStart = q.pos;
								q.skipIdent1();
								isConstructor = q.substring(ctStart, q.pos) == "constructor";
							}
						} while (false);
						addFieldHint(isConstructor, jsDocInterfaceName, true, s, args, null, fieldType, argTypes, true);
						if (templateSelf != null && addFieldHint_doc != null) {
							addFieldHint_doc.templateSelf = templateSelf;
							addFieldHint_doc.templateItems = templateItems;
						}
					}
					q_restore();
				};
			} // switch (s)
		} // while in doLoop, can continue
		} // doLoop
		doLoop();
		flushDoc();
		//
		if (project.hasGMLive) out.hasGMLive = out.hasGMLive || ui.GMLive.check(src);
	}
	
	public static function finish(orig:String, out:GmlSeekData):Void {
		GmlSeekData.apply(orig, GmlSeekData.map[orig], out);
		GmlSeekData.map.set(orig, out);
		out.comps.nameSort();
	}
	public static function addObjectChild(parentName:String, childName:String) {
		var pj = Project.current;
		pj.objectParents[childName] = parentName;
		var parChildren = pj.objectChildren[parentName];
		if (parChildren == null) {
			parChildren = [];
			pj.objectChildren.set(parentName, parChildren);
		}
		parChildren.push(childName);
	}
	public static function runSync(path:String, content:String, main:String, kind:FileKind) {
		return kind.index(path, content, main);
	} // runSync
}

typedef GmlSeekerItem = {
	path:String,
	main:String,
	kind:FileKind,
}

@:build(tools.AutoEnum.build("bit"))
@:enum abstract GmlSeekerFlags(Int) from Int to Int {
	var Ident;
	var Define;
	/** `#macro` */
	var Macro;
	/** `/// ...` */
	var Doc;
	/** `/* ...` */
	var ComBlock;
	var Cub0;
	var Cub1;
	var Comma;
	var Period;
	var Semico;
	var SetOp;
	var Line;
	var Par0;
	var Par1;
	var Sqb0;
	var Sqb1;
	var Colon;
	var Static;
	//
	public inline function has(flag:GmlSeekerFlags) {
		return this & flag != 0;
	}
}
