package synext;
import gml.GmlAPI;
import js.lib.RegExp;
import js.lib.RegExp.RegExpMatch;
import parsers.GmlReader;
import tools.Aliases;
import tools.GmlCodeTools;
import tools.JsTools;
import ui.Preferences;
using tools.RegExpTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlNullCoalescingOperator {
	public static function pre(code:GmlCode):GmlCode {
		var q = new GmlReader(code);
		var version = GmlAPI.version;
		var out = "";
		var start = 0;
		var ncSet = "nc_set";
		var ncVal = "nc_val";
		var ncValLen = ncVal.length;
		inline function flush(till:StringPos):Void {
			out += code.substring(start, till);
		}
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "@".code: q.skipStringAuto(c, version);
				case "#".code: if (q.canContextName(p)) q.readContextName(null);
				case _ if (c.isIdent0()): {
					q.skipIdent1();
					var id = q.substring(p, q.pos);
					if (id != "nc_set") continue;
					if (q.read() != "(".code) continue;
					var exprStart = q.pos;
					var depth = 0;
					while (q.loop) {
						c = q.read();
						switch (c) {
							case "/".code: switch (q.peek()) {
								case "/".code: q.skipLine();
								case "*".code: q.skip(); q.skipComment();
								default:
							};
							case '"'.code, "'".code, "@".code: q.skipStringAuto(c, version);
							case "(".code, "[".code, "{".code: depth++;
							case ")".code, "]".code, "}".code: if (--depth < 0) break;
						}
					}
					if (depth >= 0) continue;
					var expr = q.substring(exprStart, q.pos - 1);
					//
					var spaceStr:String = {
						var spStart = q.pos;
						q.skipSpaces0();
						q.substring(spStart, q.pos);
					};
					var skipValSpace_start:StringPos;
					inline function skipValSpace():Bool {
						skipValSpace_start = q.pos;
						q.skipSpaces0();
						return q.substring(skipValSpace_start, q.pos) != spaceStr;
					}
					//
					if (q.read() != "?".code) continue;
					if (skipValSpace()) continue;
					if (q.substr(q.pos, ncValLen) == ncVal) q.skip(ncValLen); else continue;
					if (skipValSpace()) continue;
					if (q.read() != ":".code) continue;
					//
					flush(p);
					out += pre(expr) + spaceStr + "??";
					start = q.pos;
					//Main.console.log(id);
				};
				default:
			}
		}
		flush(q.length);
		return out;
	}
	public static function post(code:GmlCode):GmlCode {
		var q = new GmlReader(code);
		var version = GmlAPI.version;
		var out = "";
		var start = 0;
		inline function flush(till:StringPos):Void {
			out += code.substring(start, till);
		}
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "@".code: q.skipStringAuto(c, version);
				case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
					q.readContextName(null);
				};
				case "?".code: if (q.peek() == "?".code) {
					q.skip();
					var p1 = p;
					while (p1 > 0) {
						c = q.get(p1 - 1);
						if (c.isSpace0()) p1--; else break;
					}
					var p0 = GmlCodeTools.skipDotExprBackwards(code, p1);
					var expr = code.substring(p0, p1);
					var sp = code.substring(p1, p);
					flush(p0);
					out += 'nc_set($expr)$sp?${sp}nc_val${sp}:';
					start = q.pos;
				};
				default:
			}
		}
		flush(q.length);
		return out;
	}
}