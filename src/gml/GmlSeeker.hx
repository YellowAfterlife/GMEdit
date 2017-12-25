package gml;
import ace.AceWrap.AceAutoCompleteItem;
import electron.FileSystem;
import gml.GmlAPI;
import haxe.io.Path;
import tools.Dictionary;
import yy.YyObject;
using StringTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeeker {
	public static var itemsLeft:Int = 0;
	public static function run(path:String, main:String) {
		itemsLeft++;
		FileSystem.readTextFile(path, function(err, text) {
			runSync(path, text, main);
			if (--itemsLeft <= 0) {
				GmlAPI.gmlComp.autoSort();
			}
		});
	}
	public static function runSync(orig:String, src:String, main:String) {
		switch (Path.extension(orig)) {
			case "yy": {
				var obj:YyObject = haxe.Json.parse(src);
				var dir = Path.directory(orig);
				for (ev in obj.eventList) {
					var rel = yy.YyEvent.toPath(ev.eventtype, ev.enumb, ev.id);
					var full = Path.join([dir, rel]);
					run(full, null);
				}
				return;
			};
			case "gmx": {
				var obj = gmx.SfGmx.parse(src);
				for (events in obj.findAll("events"))
				for (event in events.findAll("event"))
				for (action in event.findAll("action")) {
					var code = gmx.GmxAction.getCode(action);
					if (code != null) runSync(orig, code, null);
				}
			};
		}
		var mainTop = main;
		var out = new GmlSeekData();
		var q = new GmlReader(src);
		/**
		 * A lazy parser.
		 * You tell it what you're looking for, and it reads the input till it finds any of that.
		 */
		function find(flags:GmlSeekerFlags):String {
			while (q.loop) {
				var start = q.pos;
				var c = q.read(), s:String;
				switch (c) {
					case "\r".code, "\n".code: if (flags.has(Line)) return "\n";
					case ",".code: if (flags.has(Comma)) return ",";
					case ";".code: if (flags.has(Semico)) return ";";
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
							q.skipComment();
						};
						default:
					};
					case '"'.code, "'".code: {
						q.skipString1(c);
					};
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
		var s:String, name:String;
		while (q.loop) {
			s = find(Ident | Doc | Define | Macro);
			if (s == null) {
				//
			} else if (s.fastCodeAt(0) == "/".code) {
				if (main != null && s.indexOf("(") >= 0) {
					s = s.substring(3).trimLeft();
					if (s.startsWith("@description")) {
						s = s.substring(12).trimLeft();
					}
					//trace(main, s);
					GmlAPI.gmlDoc.set(main, GmlAPI.parseDoc(s));
					//trace(main, s);
					main = null;
				}
			} else switch (s) {
				case "#define": {
					main = find(Ident);
					if (!GmlAPI.gmlKind.exists(main)) {
						GmlAPI.gmlKind.set(main, "asset.script");
						GmlAPI.gmlComp.push(new AceAutoCompleteItem(main, "script"));
						if (main != mainTop) GmlAPI.gmlLookup.set(main, mainTop);
					}
				};
				case "#macro": {
					name = find(Ident);
					if (name == null) continue;
					var start = q.pos;
					find(Line);
					s = q.substring(start, q.pos - 1);
					var m = new GmlMacro(name, orig, s);
					out.macroList.push(m);
					out.macroMap.set(name, m);
				};
				case "globalvar": {
					while (q.loop) {
						s = find(Ident | Semico);
						if (s == ";" || GmlAPI.kwMap.exists(s)) break;
						var g = new GmlGlobal(s, orig);
						out.globalList.push(g);
						out.globalMap.set(s, g);
					}
				};
				case "enum": {
					name = find(Ident);
					if (name == null) continue;
					if (find(Cub0) == null) continue;
					var en = new GmlEnum(name, orig);
					out.enumList.push(en);
					out.enumMap.set(name, en);
					while (q.loop) {
						s = find(Ident | Cub1);
						if (s == null || s == "}") break;
						en.names.push(s);
						en.items.set(s, true);
						var ac = new AceAutoCompleteItem(name + "." + s, "enum");
						en.compList.push(ac);
						en.compMap.set(s, ac);
						s = find(Comma | SetOp | Cub1);
						if (s == null || s == "}") break;
						if (s == "=") {
							s = find(Comma | Cub1);
							if (s == null || s == "}") break;
						}
					}
				};
			} // switch (s)
		} // while
		GmlSeekData.apply(GmlSeekData.map[orig], out);
		GmlSeekData.map.set(orig, out);
	} // runSync
}
@:build(tools.AutoEnum.build("bit"))
@:enum abstract GmlSeekerFlags(Int) from Int to Int {
	var Ident;
	var Define;
	var Macro;
	var Doc;
	var Cub0;
	var Cub1;
	var Comma;
	var Semico;
	var SetOp;
	var Line;
	//
	public inline function has(flag:GmlSeekerFlags) {
		return this & flag != 0;
	}
}
