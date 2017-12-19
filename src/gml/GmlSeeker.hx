package gml;
import ace.AceWrap.AceAutoCompleteItem;
import gml.GmlAPI;
import tools.Dictionary;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeeker {
	public static var itemsLeft:Int = 0;
	public static function run(path:String, main:String) {
		itemsLeft++;
		Main.nodefs.readTextFile(path, function(err, text) {
			runSync(path, text, main);
			if (--itemsLeft <= 0) {
				GmlAPI.gmlComp.autoSort();
			}
		});
	}
	public static function runSync(orig:String, src:String, main:String) {
		var out = new GmlSeekData();
		var pos = 0;
		var len = src.length;
		inline function loop():Bool {
			return pos < len;
		}
		inline function skip():Void {
			pos += 1;
		}
		inline function next():Int {
			return src.fastCodeAt(pos++);
		}
		inline function peek(ofs:Int = 0):Int {
			return src.fastCodeAt(ofs != 0 ? pos + ofs : pos);
		}
		inline function at(i:Int):Int {
			return src.fastCodeAt(i);
		}
		inline function sub(start:Int, end:Int):String {
			return src.substring(start, end);
		}
		inline function isIdent1(c:Int):Bool {
			return c == "_".code
				|| c >= "a".code && c <= "z".code
				|| c >= "A".code && c <= "Z".code
				|| c >= "0".code && c <= "9".code;
		}
		function find(flags:GmlSeekerFlags):String {
			while (loop()) {
				var start = pos;
				var c = next(), q:Int, s:String;
				switch (c) {
					case "\r".code, "\n".code: if (flags.has(Line)) return "\n";
					case ",".code: if (flags.has(Comma)) return ",";
					case ";".code: if (flags.has(Semico)) return ";";
					case "{".code: if (flags.has(Cub0)) return "{";
					case "}".code: if (flags.has(Cub1)) return "}";
					case "=".code: if (flags.has(SetOp) && peek() != "=".code) return "=";
					case "/".code: switch (peek()) {
						case "/".code: {
							skip();
							while (loop()) switch (peek()) {
								case "\n".code, "\r".code: break;
								default: skip();
							}
							if (flags.has(Doc) && at(start + 2) == "/".code) {
								return sub(start, pos);
							}
						};
						case "*".code: {
							skip();
							do {
								c = next();
							} while (loop() && (c != "*".code || peek() != "/".code));
							if (loop()) skip();
						};
						default:
					};
					case '"'.code, "'".code: {
						q = peek();
						while (q != c && loop()) {
							skip(); q = peek();
						}
						if (loop()) skip();
					};
					case "#".code: {
						while (loop()) {
							c = peek();
							if (isIdent1(c)) {
								skip();
							} else break;
						}
						if (pos > start + 1) {
							s = sub(start, pos);
							switch (s) {
								case "#define": if (flags.has(Define)) return s;
								case "#macro": if (flags.has(Macro)) return s;
								default:
							}
						}
					};
					default: {
						if (c >= "_".code
						|| (c >= "A".code && c <= "Z".code)
						|| (c >= "a".code && c <= "z".code)
						) {
							while (loop()) {
								c = peek();
								if (isIdent1(c)) {
									skip();
								} else break;
							}
							if (flags.has(Ident)) return sub(start, pos);
						}
					};
				}
			}
			return null;
		} // find
		var s:String, name:String;
		while (loop()) {
			s = find(Ident | Doc | Define);
			if (s == null) {
				//
			} else if (s.fastCodeAt(0) == "/".code) {
				if (main != null) {
					trace(main, s);
					GmlAPI.gmlDoc.set(main, GmlAPI.parseDoc(s.substring(3).ltrim()));
					//trace(main, s);
					main = null;
				}
			} else switch (s) {
				case "#define": {
					main = find(Ident);
				};
				case "#macro": {
					name = find(Ident);
					if (name == null) continue;
					var start = pos;
					find(Line);
					s = sub(start, pos - 1);
					// GMS2-only!
				};
				case "globalvar": {
					while (loop()) {
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
					while (loop()) {
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
@:build(tools.IntEnum.build("bit"))
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
