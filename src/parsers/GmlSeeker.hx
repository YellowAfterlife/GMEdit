package parsers;
import ace.AceWrap.AceAutoCompleteItem;
import electron.FileSystem;
import electron.FileWrap;
import gml.GmlAPI;
import gmx.*;
import yy.*;
import gml.*;
import haxe.io.Path;
import js.RegExp;
import parsers.GmlReader;
import tools.Dictionary;
import ui.Preferences;
import ui.TreeView;
import yy.YyObject;
using StringTools;
using tools.NativeString;

/**
 * Looks for definitions in files/code (for syntax highlighing, auto-completion, etc.)
 * @author YellowAfterlife
 */
class GmlSeeker {
	public static var itemsLeft:Int = 0;
	public static function start() {
		itemsLeft = 0;
	}
	public static function run(path:String, main:String) {
		itemsLeft++;
		function next(err, text) {
			if (runSync(path, text, main)) {
				runNext();
			}
		}
		FileWrap.readTextFile(path, next);
	}
	private static function runNext():Void {
		if (--itemsLeft <= 0) {
			GmlAPI.gmlComp.autoSort();
			if (Project.current != null) {
				Project.nameNode.innerText = Project.current.displayName;
				if (Project.current.hasGMLive) ui.GMLive.updateAll();
			}
			Main.aceEditor.session.bgTokenizer.start(0);
		}
	}
	
	private static var jsDoc_full = new RegExp("^///\\s*" // start
		+ "(?:@desc(?:ription)?\\s+)?" // opt: "@desc "
		+ "\\w+(\\(.+)");
	private static var jsDoc_param = new RegExp("^///\\s*@(?:arg|param|argument)"
		+ "\\s+(\\S+(?:\\s+=.+)?)");
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
	
	private static function runSyncImpl(
		orig:String, src:String, main:String, out:GmlSeekData, locals:GmlLocals
	):Void {
		var mainTop = main;
		var sub = null;
		var q = new GmlReader(src);
		var v = GmlAPI.version;
		var row = 0;
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
					case ";".code: if (flags.has(Semico)) return ";";
					case "(".code: if (flags.has(Par0)) return "(";
					case ")".code: if (flags.has(Par1)) return ")";
					case "[".code: if (flags.has(Sqb0)) return "[";
					case "]".code: if (flags.has(Sqb1)) return "]";
					case "{".code: if (flags.has(Cub0)) return "{";
					case "}".code: if (flags.has(Cub1)) return "}";
					case "=".code: if (flags.has(SetOp) && q.peek() != "=".code) return "=";
					case "/".code: switch (q.peek()) {
						case "/".code: {
							q.skip();
							q.skipLine();
							if (flags.has(Doc) && q.get(start + 2) == "/".code) {
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
					case '"'.code, "'".code, "`".code, "@".code: row += q.skipStringAuto(c, v);
					case "#".code: {
						while (q.loop) {
							c = q.peek();
							if (c.isIdent1()) {
								q.skip();
							} else break;
						}
						if (q.pos > start + 1) {
							s = q.substring(start, q.pos);
							switch (s) {
								case "#define": if (flags.has(Define)) {
									if (start == 0) return s;
									c = q.get(start - 1);
									if (c == "\r".code || c == "\n".code) {
										return s;
									}
								};
								case "#macro": if (flags.has(Macro)) return s;
								default:
							}
						}
					};
					default: {
						if (c.isIdent0()) {
							while (q.loop) {
								c = q.peek();
								if (c.isIdent1()) {
									q.skip();
								} else break;
							}
							if (flags.has(Ident)) return q.substring(start, q.pos);
						}
					};
				}
			}
			return null;
		} // find
		var mainComp:AceAutoCompleteItem = main != null ? GmlAPI.gmlAssetComp[main] : null;
		var s:String, name:String, start:Int, doc:GmlFuncDoc;
		var p:Int, flags:Int, mt:RegExpMatch;
		while (q.loop) {
			s = find(Ident | Doc | Define | Macro);
			if (s == null) {
				//
			}
			else if (s.fastCodeAt(0) == "/".code) {
				if (main != null) {
					var check = true, mt;
					if (v.hasJSDoc()) {
						mt = jsDoc_param.exec(s);
						if (mt != null) {
							doc = out.docMap[main];
							if (doc == null) {
								doc = GmlFuncDoc.parse(main + "()");
								doc.acc = true;
								out.docList.push(doc);
								out.docMap.set(main, doc);
							}
							if (doc.acc) {
								doc.args.push(mt[1]);
								if (mainComp != null) {
									mainComp.doc = doc.getAcText();
								}
							}
							check = false;
						}
					}
					if (check) {
						mt = jsDoc_full.exec(s);
						if (mt != null) {
							if (!out.docMap.exists(main)) {
								doc = GmlFuncDoc.parse(main + mt[1]);
								out.docList.push(doc);
								out.docMap.set(main, doc);
								if (mainComp != null && mainComp.doc == null) {
									mainComp.doc = s;
								}
							}
							check = false;
						} else if (v.hasScriptArgs()) {
							// `#define func(a, b)\n/// does things` -> `func(a, b) does things`
							s = s.substring(3).trimLeft();
							doc = out.docMap[main];
							if (doc == null) {
								if (gmlDoc_full.test(s)) {
									doc = GmlFuncDoc.parse(s);
									doc.name = main;
									doc.pre = main + "(";
								} else doc = GmlFuncDoc.parse(main + "(...) " + s);
								out.docList.push(doc);
								out.docMap.set(main, doc);
							} else {
								if (gmlDoc_full.test(s)) {
									GmlFuncDoc.parse(s, doc);
									doc.name = main;
									doc.pre = main + "(";
								} else doc.post += " " + s;
							}
						}
					}
				}
			}
			else switch (s) {
				case "#define": {
					main = find(Ident);
					start = q.pos;
					sub = main;
					row = 0;
					setLookup(main, true);
					locals = new GmlLocals();
					out.locals.set(main, locals);
					if (v.hasScriptArgs()) {
						s = find(Line | Par0);
						if (s == "(") {
							while (q.loop) {
								s = find(Ident | Line | Par1);
								if (s == ")" || s == "\n" || s == null) break;
								locals.add(s);
							}
							doc = GmlFuncDoc.parse(main + q.substring(start, q.pos));
							out.docList.push(doc);
							out.docMap.set(main, doc);
						}
					}
					//
					mainComp = new AceAutoCompleteItem(main, "script",
						q.pos > start ? main + q.substring(start, q.pos) : null);
					out.compList.push(mainComp);
					out.compMap.set(main, mainComp);
					out.kindList.push(main);
					out.kindMap.set(main, "asset.script");
				};
				case "#macro": {
					name = find(Ident);
					if (name == null) continue;
					start = q.pos;
					find(Line);
					s = q.substring(start, q.pos - 1);
					var m = new GmlMacro(name, orig, s.trimBoth());
					out.kindList.push(name);
					out.kindMap.set(name, "macro");
					out.compList.push(m.comp);
					out.compMap.set(name, m.comp);
					out.macroList.push(m);
					out.macroMap.set(name, m);
					setLookup(name, true);
				};
				case "globalvar": {
					while (q.loop) {
						s = find(Ident | Semico);
						if (s == null || s == ";" || GmlAPI.kwFlow.exists(s)) break;
						var g = new GmlGlobalVar(s, orig);
						out.globalVarList.push(g);
						out.globalVarMap.set(s, g);
						out.compList.push(g.comp);
						out.compMap.set(s, g.comp);
						out.kindList.push(s);
						out.kindMap.set(s, "globalvar");
						setLookup(s);
					}
				};
				case "global": {
					if (find(Period | Ident) == ".") {
						s = find(Ident);
						if (s != null && out.globalFieldMap[s] == null) {
							var gfd = GmlAPI.gmlGlobalFieldMap[s];
							if (gfd == null) {
								gfd = new GmlGlobalField(s, "global");
								GmlAPI.gmlGlobalFieldMap.set(s, gfd);
							}
							out.globalFieldList.push(gfd);
							out.globalFieldMap.set(s, gfd);
							out.globalFieldComp.push(gfd.comp);
						}
					}
				};
				case "var": {
					while (q.loop) {
						name = find(Ident);
						if (name == null) break;
						locals.add(name);
						p = q.pos;
						flags = SetOp | Comma | Semico | Ident | ComBlock;
						s = find(flags);
						if (s.startsWith("/*")) { // name/*...*/
							mt = localType.exec(s);
							if (mt != null) {
								locals.type.set(name, mt[1]);
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
								p = q.pos;
								s = find(Par0 | Par1 | Sqb0 | Sqb1 | Cub0 | Cub1
									| Comma | Semico | Ident);
								// EOF:
								if (s == null) {
									exit = true;
									break;
								}
								switch (s) {
									case "(", "[", "{": depth += 1;
									case ")", "]", "}": depth -= 1;
									case ",": if (depth == 0) break;
									case ";": exit = true; break;
									default: { // ident
										if (GmlAPI.kwFlow[s]) {
											q.pos = p;
											exit = true;
											break;
										}
									};
								}
							}
							if (exit) break;
						} else {
							// EOF or `var name something_else`
							q.pos = p;
							break;
						}
					}
				};
				case "enum": {
					name = find(Ident);
					if (name == null) continue;
					if (find(Cub0) == null) continue;
					var en = new GmlEnum(name, orig);
					out.enumList.push(en);
					out.enumMap.set(name, en);
					out.compList.push(new AceAutoCompleteItem(name, "enum"));
					setLookup(name);
					var nextVal:Null<Int> = 0;
					while (q.loop) {
						s = find(Ident | Cub1);
						if (s == null || s == "}") break;
						en.names.push(s);
						en.items.set(s, true);
						var ac = new AceAutoCompleteItem(name + "." + s, "enum");
						var acf = new AceAutoCompleteItem(s, "enum");
						en.compList.push(ac);
						en.fieldComp.push(acf);
						en.compMap.set(s, ac);
						s = find(Comma | SetOp | Cub1);
						if (s == "=") {
							var vp = q.pos;
							s = find(Comma | Cub1);
							var val = parseConst(q.substring(vp, q.pos - 1).trimBoth());
							if (val != null) {
								acf.doc = ac.doc = "" + val;
								nextVal = val + 1;
							} else nextVal = null;
						} else if (nextVal != null) {
							acf.doc = ac.doc = "" + (nextVal++);
						}
						if (s == null || s == "}") break;
					}
				};
				default: { // maybe an instance field assignment
					// skip if it's a local/built-in/project/extension identifier:
					if (locals.kind[s] != null) continue;
					if (GmlAPI.gmlKind[s] != null) continue;
					if (GmlAPI.extKind[s] != null) continue;
					if (GmlAPI.stdKind[s] != null) continue;
					var skip = false, i;
					// skip if it's `field.some`
					i = q.pos - s.length;
					while (--i >= 0) switch (q.get(i)) {
						case " ".code, "\t".code, "\r".code, "\n".code: { };
						case ".".code: skip = true; break;
						default: break;
					}
					if (skip) continue;
					// skip unless it's `some =` (and no `some ==`)
					i = q.pos;
					while (i < q.length) switch (q.get(i++)) {
						case " ".code, "\t".code, "\r".code, "\n".code: { };
						case "=".code: skip = q.get(i) == "=".code; break;
						default: skip = true; break;
					}
					if (skip) continue;
					// that's an instance variable then
					if (out.instFieldMap[s] == null) {
						var fd = GmlAPI.gmlInstFieldMap[s];
						if (fd == null) {
							fd = new GmlGlobalField(s, "variable");
							GmlAPI.gmlInstFieldMap.set(s, fd);
						}
						out.instFieldList.push(fd);
						out.instFieldMap.set(s, fd);
						out.instFieldComp.push(fd.comp);
					}
				};
			} // switch (s)
		} // while
		//
		if (Project.current.hasGMLive) out.hasGMLive = out.hasGMLive || ui.GMLive.check(src);
	}
	
	static inline function finish(orig:String, out:GmlSeekData):Void {
		GmlSeekData.apply(orig, GmlSeekData.map[orig], out);
		GmlSeekData.map.set(orig, out);
		out.compList.autoSort();
	}
	static inline function addObjectChild(parentName:String, childName:String) {
		var pj = Project.current;
		var parChildren = pj.objectChildren[parentName];
		if (parChildren == null) {
			parChildren = [];
			pj.objectChildren.set(parentName, parChildren);
		}
		parChildren.push(childName);
	}
	static function runYyObject(orig:String, src:String) {
		var obj:YyObject = haxe.Json.parse(src);
		var dir = Path.directory(orig);
		//
		var parentName = Project.current.yyObjectNames[obj.parentObjectId];
		if (parentName != null) addObjectChild(parentName, obj.name);
		//
		if (Preferences.current.assetThumbs) {
			var spriteId = obj.spriteId;
			if (spriteId != YyGUID.zero) {
				var pj = Project.current;
				var res = pj.yyResources[spriteId];
				if (res != null) {
					var spritePath = res.Value.resourcePath;
					pj.readJsonFile(spritePath, function(e, sprite:YySprite) {
						var frame = sprite.frames[0];
						if (frame == null) return;
						var framePath = Path.join([Path.directory(spritePath), frame.id + ".png"]);
						var frameURL = pj.getImageURL(framePath);
						if (frameURL != null) TreeView.setThumb(orig, frameURL);
					});
				}
			}
		}
		//
		var out = new GmlSeekData();
		var eventsLeft = 0;
		var eventFiles = [];
		for (ev in obj.eventList) {
			var rel = yy.YyEvent.toPath(ev.eventtype, ev.enumb, ev.id);
			var full = Path.join([dir, rel]);
			var name = YyEvent.toString(ev.eventtype, ev.enumb, ev.collisionObjectId);
			eventsLeft += 1;
			eventFiles.push({
				name: name,
				full: full,
			});
		}
		if (eventFiles.length == 0) return true;
		for (file in eventFiles) (function(name, full) {
			function procEvent(err, code) {
				if (err == null) try {
					var locals = new GmlLocals();
					out.locals.set(name, locals);
					runSyncImpl(orig, code, null, out, locals);
				} catch (_:Dynamic) {
					//
				}
				if (--eventsLeft <= 0) {
					finish(orig, out);
					runNext();
				}
			}
			FileWrap.readTextFile(full, procEvent);
		})(file.name, file.full);
		return false;
	}
	static function runGmxObject(orig:String, src:String) {
		var obj = SfGmx.parse(src);
		var out = new GmlSeekData();
		//
		var parentName = obj.findText("parentName");
		if (parentName != "<undefined>") {
			var objectName = Path.withoutExtension(Path.withoutExtension(Path.withoutDirectory(orig)));
			addObjectChild(parentName, objectName);
		}
		//
		if (Preferences.current.assetThumbs) {
			var sprite = obj.findText("spriteName");
			if (sprite != "<undefined>") {
				var framePath = Path.join(["sprites", "images", sprite + "_0.png"]);
				var frameURL = Project.current.getImageURL(framePath);
				if (frameURL != null) TreeView.setThumb(orig, frameURL);
			}
		}
		//
		for (events in obj.findAll("events"))
		for (event in events.findAll("event")) {
			var etype = Std.parseInt(event.get("eventtype"));
			var ename = event.get("ename");
			var enumb:Int = ename == null ? Std.parseInt(event.get("enumb")) : null;
			var name = GmxEvent.toString(etype, enumb, ename);
			var locals = new GmlLocals();
			out.locals.set(name, locals);
			for (action in event.findAll("action")) {
				var code = GmxAction.getCode(action);
				if (code != null) {
					runSyncImpl(orig, code, null, out, locals);
				}
			}
		}
		finish(orig, out);
		return true;
	}
	public static function runSync(orig:String, src:String, main:String) {
		switch (Path.extension(orig)) {
			case "yy": return runYyObject(orig, src);
			case "gmx": return runGmxObject(orig, src);
		}
		var src_ncr = src;
		src = GmlExtCoroutines.pre(src);
		//
		var out = new GmlSeekData();
		out.hasCoroutines = src_ncr != src;
		out.main = main;
		var locals = new GmlLocals();
		out.locals.set("", locals);
		runSyncImpl(orig, src, main, out, locals);
		finish(orig, out);
		return true;
	} // runSync
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
	//
	public inline function has(flag:GmlSeekerFlags) {
		return this & flag != 0;
	}
}
