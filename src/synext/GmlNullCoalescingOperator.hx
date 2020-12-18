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
					// nc_set(a) ¦? nc_val.b : c
					if (q.read() != "?".code) continue;
					if (skipValSpace()) continue;
					if (q.readIdent() != ncVal) continue;
					
					if (q.peek() == ".".code) { // nc_set(a) ? nc_val¦.b : c
						q.skip(); // nc_val.¦b
						
						var fdStart = q.pos;
						q.skipSpaces0(); // optional spacing before field name
						if (q.readIdent() == null) continue;
						var fdSuffix = q.substring(fdStart, q.pos); // nc_val.b¦
						
						if (skipValSpace()) continue;
						if (q.read() != ":".code) continue;
						if (skipValSpace()) continue;
						if (q.readIdent() != "undefined") continue;
						if (q.read() != ")".code) continue;
						
						//
						if (q.get(p - 1) != "(".code) continue;
						flush(p - 1);
						out += pre(expr) + spaceStr + "?." + fdSuffix;
					} else {
						if (skipValSpace()) continue;
						if (q.read() != ":".code) continue;
						//
						flush(p);
						out += pre(expr) + spaceStr + "??";
					}
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
		var segments = [];
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
				case "?".code: {
					var c1 = q.peek();
					if (c1 == "?".code || c1 == ".".code) {
						q.skip();
						//
						var fdSuffix:String;
						if (c1 == ".".code) {
							var fdStart = q.pos;
							q.skipSpaces0();
							if (!q.peek().isIdent0()) continue; // don't convert `z?.1:.2`
							q.skipIdent1();
							fdSuffix = q.substring(fdStart, q.pos);
						} else fdSuffix = null;
						//
						var exprEnd = p;
						while (exprEnd > 0) {
							c = q.get(exprEnd - 1);
							if (c.isSpace0()) exprEnd--; else break;
						}
						var exprStart = GmlCodeTools.skipDotExprBackwards(code, exprEnd);
						var expr = code.substring(exprStart, exprEnd);
						//
						var sp = code.substring(exprEnd, p);
						segments.push({
							start: exprStart,
							end: q.pos,
							expr: expr,
							space: sp,
							fdSuffix: fdSuffix,
							kind: c1,
							recurse: false,
						});
					};
				};
				default:
			}
		}
		//
		var out = "";
		var start = 0;
		inline function flush(till:StringPos):Void {
			out += code.substring(start, till);
		}
		// merge segments containing other segments:
		var i = segments.length;
		while (--i >= 0) {
			var seg = segments[i];
			while (i > 0) {
				var s1 = segments[i - 1];
				if (s1.start >= seg.start && s1.end <= seg.end) {
					seg.recurse = true;
					segments.splice(i - 1, 1);
					i -= 1;
				} else break;
			}
		}
		//
		for (seg in segments) {
			flush(seg.start);
			var sp = seg.space;
			var expr = seg.expr;
			if (seg.recurse) expr = post(expr);
			if (seg.kind == ".".code) {
				out += '(nc_set($expr)'
					+ sp + "?"
					+ sp + "nc_val." + seg.fdSuffix
					+ sp + ":"
					+ sp + "undefined"
				+ ')';
			} else {
				out += 'nc_set($expr)${sp}?${sp}nc_val${sp}:';
			}
			start = seg.end;
		}
		flush(q.length);
		//
		return out;
	}
}