package parsers;

import ace.AceWrap.AcePos;
import gml.GmlVersion;
import tools.CharCode;
import tools.StringReader;
using tools.NativeString;

/**
 * Extends regular string parser with a set of GML-related helpers.
 * @author YellowAfterlife
 */
class GmlReader extends StringReader {
	public inline function skipWhile(fn:CharCode-> Bool) {
		while (loop) {
			if (fn(peek())) {
				skip();
			} else break;
		}
	}
	
	/** Skips to the end of the current line */
	public inline function skipLine() {
		while (loop) {
			switch (peek()) {
				case "\n".code, "\r".code: // ->
				default: skip(); continue;
			}; break;
		}
	}
	
	/** Skips a single `\n` / `\r\n`, if any */
	public inline function skipLineEnd() {
		if (loop) switch (peek()) {
			case "\r".code: {
				skip();
				if (peek() == "\n".code) skip();
			};
			case "\n".code: skip();
		}
	}
	
	private static function skipComment_1(s:String, p:Int) {
		if (s.fastSub(p, 5) == "event") return true;
		switch (s.fastSub(p, 6)) {
			case "moment", "action": return true;
		}
		if (s.fastSub(p, 7) == "section") return true;
		return false;
	}
	
	/** Skips past the end of a comment-block */
	public inline function skipComment() {
		var n = 0;
		while (loop) {
			var c = read();
			if (c == "\n".code) {
				n += 1;
				if (peek() == "#".code && skipComment_1(source, pos + 1)) break;
			} else if (c == "*".code && peek() == "/".code) {
				skip();
				break;
			}
		}
		return n;
	}
	
	public inline function skipString1(qc:Int):Int {
		var c = peek(), n = 0;
		while (c != qc && loop) {
			skip(); c = peek();
			if (c == "\n".code) n++;
		}
		if (loop) skip();
		return n;
	}
	
	public inline function skipString2():Int {
		var n = 0;
		var c = peek();
		while (c != '"'.code && loop) {
			if (c == "\\".code) {
				skip(); c = peek();
				switch (c) {
					case "x".code: skip(2);
					case "u".code: skip(4);
					case "\n".code: n += 1; skip();
					default: skip();
				}
			} else skip();
			c = peek();
		}
		if (loop) skip();
		return n;
	}
	
	public inline function skipStringAuto(startquote:CharCode, version:GmlVersion):Int {
		switch (startquote) {
			case '"'.code: {
				if (version.hasStringEscapeCharacters()) {
					return skipString2();
				} else return skipString1('"'.code);
			};
			case "'".code: {
				if (version.hasSingleQuoteStrings()) {
					return skipString1("'".code);
				} else return 0;
			};
			case "`".code: {
				if (version.hasTemplateStrings()) {
					return skipString1("`".code);
				} else return 0;
			};
			case "@".code: {
				if (version.hasLiteralStrings()) {
					var c = read();
					if (c == '"'.code || c == "'".code) {
						return skipString1(c);
					} else return 0;
				} else return 0;
			};
			default: return 0;
		}
	}
	
	/** Skips spaces/tabs */
	public inline function skipSpaces0() {
		while (loop) {
			switch (peek()) {
				case " ".code, "\t".code: {
					skip(); continue;
				};
			}; break;
		}
	}
	
	/** Skips spaces, tabs, `\r`, `\n` */
	public inline function skipSpaces1() {
		while (loop) {
			switch (peek()) {
				case " ".code, "\t".code, "\r".code, "\n".code: {
					skip(); continue;
				};
			}; break;
		}
	}
	
	public function skipSpaces1x(till:Int) {
		while (pos < till) switch (peek()) {
			case " ".code, "\t".code, "\r".code, "\n".code: skip();
			default: break;
		}
	}
	
	public inline function skipIdent1() {
		while (loop) {
			if (peek().isIdent1()) {
				skip();
			} else break;
		}
	}
	
	public inline function skipEventName() {
		while (loop) {
			var c = peek();
			if (c.isIdent1() || c == ":".code) {
				skip();
			} else break;
		}
	}
	
	/** ("obj_some") this"#¦event step" -> "obj_some(step)" this"#event step¦" */
	public inline function readContextName(name:String) {
		var p = pos;
		skipIdent1();
		var preproc = substring(p - 1, pos);
		switch (preproc) {
			case "#define", "#event", "#moment": {
				skipSpaces0();
				p = pos;
				inline function next():String {
					return substring(p, pos);
				}
				switch (preproc) {
					case "#define": {
						skipIdent1();
						return next();
					};
					case "#event": {
						skipEventName();
						return name != null ? name + "(" + next() + ")" : next();
					};
					case "#moment": {
						skipIdent1();
						return name != null ? name + "(" + next() + ")" : next();
					};
					default: return null;
				}
			};
			default: return null;
		}
	}
	
	/** Skips comments and whitespace */
	public function skipNops(?till:Int):Int {
		var n = 0;
		if (till == null) till = length;
		while (pos < till) {
			var c = peek();
			switch (c) {
				case " ".code, "\t".code, "\r".code: skip();
				case "\n".code: skip(); n += 1;
				case "/".code: switch (peek(1)) {
					case "/".code: skipLine();
					case "*".code: skip(2); n += skipComment();
					default: break;
				};
				default: break;
			}
		}
		return n;
	}
	
	/**
	 * this"var a=¦1+f(1,2)," -> this"var a=1+f(1,2)¦,"
	 * It's not _very_ smart
	 */
	public function skipVarExpr(v:GmlVersion, ?ret:Bool):Int {
		var start = pos;
		var depth = 0;
		var n:Int = 0;
		while (pos < length) {
			var p = pos;
			var c:CharCode = read();
			switch (c) {
				case " ".code, "\t".code, "\r".code:
				case "\n".code: n += 1;
				case "/".code: switch (peek()) {
					case "/".code: skipLine();
					case "*".code: skip(); skipComment();
					default:
				};
				case "(".code, "[".code, "{".code: depth += 1;
				case ")".code, "]".code, "}".code: depth -= 1;
				case ",".code: if (depth == 0) { pos = p; break; }
				case ";".code: pos = p; break;
				case '"'.code, "'".code, "@".code, "`".code: skipStringAuto(c, v);
				case "#".code: if (p == 0 || get(p - 1) == "\n".code) {
					var ctx = readContextName(null);
					if (ctx != null) { pos = p; break; }
				};
				default: {
					if (c.isIdent0()) {
						skipIdent1();
						if (gml.GmlAPI.kwFlow[substring(p, pos)]) {
							pos = p;
							break;
						}
					}
				};
			}
		}
		return n;
	}
	private static var rxVarType = new js.RegExp("^/\\*[ \t]*:[ \t]*(\\w+)\\*/$");
	public function skipVars(fn:SkipVarsData->Void, v:GmlVersion, isArgs:Bool):Int {
		var n = 0;
		var d:SkipVarsData = {
			name: null, name0: 0, name1: 0,
			type: null, type0: 0, type1: 0,
			expr0: 0, expr1: 0, opt: false,
		};
		skipNops();
		var till:Int;
		if (isArgs) {
			till = source.indexOf("\n", pos);
			if (till < 0) till = length;
		} else till = length;
		while (pos < till) {
			var c = peek();
			if (!c.isIdent0()) break;
			var p = pos;
			d.name0 = p;
			if (peek() == "?".code) {
				d.opt = true; skip(); skipNops();
			} else d.opt = false;
			skipIdent1();
			d.name1 = pos;
			d.name = substring(p, pos);
			// handle `:type` or `/*:type*/`:
			skipSpaces1x(till);
			d.type0 = pos;
			var type = null;
			if (peek() == ":".code) {
				skip(); skipSpaces1x(till);
				var p1 = pos;
				skipIdent1();
				d.type = pos > p1 ? substring(p1, pos) : null;
			} else if (peek() == "/".code && peek(1) == "*".code) {
				p = pos;
				skip(2); skipComment();
				var mt = rxVarType.exec(substring(p, pos));
				d.type = mt != null ? mt[1] : null;
			} else d.type = null;
			d.type1 = pos;
			// see if there's `= value`:
			skipSpaces1x(till);
			if (peek() == "=".code) {
				skip(); skipSpaces1();
				d.expr0 = pos;
				skipVarExpr(v, true);
			} else d.expr0 = pos;
			d.expr1 = pos;
			skipNops(till);
			fn(d);
			if (peek() != ",".code) break;
			skip();
			skipNops(till);
		}
		return n;
	}
	/**
	 * `a = {p0}v{p1} + 1;` -> false
	 * `{p0}v{p1} = 1;` -> true
	 * `++{p0}v{p1}` -> true
	 */
	public function checkWrites(p0:Int, p1:Int) {
		// prefix:
		while (--p0 >= 0) switch (get(p0)) {
			case " ".code, "\t".code, "\r".code, "\n".code: { };
			case "+".code: if (get(--p0) == "+".code) return true; else break;
			case "-".code: if (get(--p0) == "-".code) return true; else break;
			default: break;
		}
		// postfix/setop:
		while (p1 < length) switch (get(p1++)) {
			case " ".code, "\t".code, "\r".code, "\n".code: { };
			case "=".code: return get(p1) != "=".code;
			case "+".code: switch (get(p1)) {
				case "+".code, "=".code: return true;
				default: return false;
			};
			case "-".code: switch (get(p1)) {
				case "-".code, "=".code: return true;
				default: return false;
			};
			case "*".code, "/".code, "%".code, "^".code, "|".code, "&".code: {
				return get(p1) == "=".code;
			};
			default: return false;
		}
		return false;
	}
	
	/** offset to row+column */
	public function getPos(p:Int):AcePos {
		var row = 0;
		var rowStart = 0;
		for (i in 0 ... p) {
			if (get(i) == "\n".code) {
				row += 1;
				rowStart = i + 1;
			}
		}
		return new AcePos(p - rowStart, row);
	}
}
typedef SkipVarsData = {
	name:String, name0:Int, name1:Int,
	type:String, type0:Int, type1:Int,
	expr0:Int, expr1:Int, opt:Bool,
};
