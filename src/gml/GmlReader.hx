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
		while (loop) {
			var c = read();
			if (c == "*".code && peek() == "/".code) break;
		}
		if (loop) skip();
	}
	
	public inline function skipString1(qc:Int):Void {
		var c = peek();
		while (c != qc && loop) {
			skip(); c = peek();
		}
		if (loop) skip();
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
