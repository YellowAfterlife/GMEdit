package parsers;

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
	public inline function skipSpaces1() {
		while (loop) {
			switch (peek()) {
				case " ".code, "\t".code, "\r".code, "\n".code: {
					skip(); continue;
				};
			}; break;
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
}
