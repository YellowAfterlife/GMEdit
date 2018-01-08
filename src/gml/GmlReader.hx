package gml;

import tools.CharCode;
import tools.StringReader;

/**
 * ...
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
	/** Skips past the end of a comment-block */
	public inline function skipComment() {
		var n = 0;
		while (loop) {
			var c = read();
			if (c == "\n".code) {
				n += 1;
			} else if (c == "*".code && peek() == "/".code) break;
		}
		if (loop) skip();
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
					return skipString1(read());
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
}
