package gml;

import tools.StringReader;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlReader extends StringReader {
	/** Skips to the end of the current line */
	public inline function skipLine() {
		while (loop) switch (peek()) {
			case "\n".code, "\r".code: break;
			default: skip();
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
		return n;
	}
	
	public inline function skipSpaces0() {
		while (loop) {
			var c = peek();
			if (c.isSpace0()) {
				skip();
			} else break;
		}
	}
	
}
