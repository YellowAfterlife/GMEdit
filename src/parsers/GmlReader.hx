package parsers;

import ace.extern.*;
import gml.GmlVersion;
import tools.CharCode;
import tools.StringReader;
using tools.NativeString;

/**
 * Extends regular string parser with a set of GML-related helpers.
 * @author YellowAfterlife
 */
class GmlReader extends StringReader {
	//
	public var loop(get, never):Bool;
	private function get_loop():Bool {
		return (pos < length);
	}
	//
	public var eof(get, never):Bool;
	private function get_eof():Bool {
		return (pos >= length);
	}
	
	/** inlined; for layered parser, will not go over boundaries */
	public var loopLocal(get, never):Bool;
	private inline function get_loopLocal():Bool {
		return pos < length;
	}
	
	//
	public var version:GmlVersion;
	public function new(gmlCode:String, ?version:GmlVersion) {
		super(gmlCode);
		this.version = version != null ? version : gml.Project.current.version;
	}
	
	/** Skips to the end of the current line */
	public function skipLine() {
		while (loopLocal) {
			switch (peek()) {
				case "\n".code, "\r".code: // ->
				default: skip(); continue;
			}; break;
		}
	}
	
	/** Skips a single `\n` / `\r\n`, if any */
	public function skipLineEnd() {
		if (loopLocal) switch (peek()) {
			case "\r".code: {
				skip();
				if (peek() == "\n".code) skip();
			};
			case "\n".code: skip();
		}
	}
	
	/** Unclosed multiline comments are legal in GML so we need to handle that */
	private static function skipComment_1(s:String, p:Int):Bool {
		if (s.fastSub(p, 5) == "event") return true;
		switch (s.fastSub(p, 6)) {
			case "moment", "action", "target", "define": return true;
		}
		if (s.fastSub(p, 7) == "section") return true;
		return false;
	}
	
	/** Skips past the end of a comment-block */
	public function skipComment() {
		var n = 0;
		while (loopLocal) {
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
	
	public function skipString1(qc:Int):Int {
		var c = peek(), n = 0;
		while (c != qc && loopLocal) {
			skip(); c = peek();
			if (c == "\n".code) n++;
		}
		if (loopLocal) skip();
		return n;
	}
	
	public function skipString2():Int {
		var n = 0;
		var c = peek();
		while (c != '"'.code && loopLocal) {
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
		if (loopLocal) skip();
		return n;
	}
	
	public function skipStringTemplate(version:GmlVersion):Int {
		var n = 0;
		var esc = version.hasStringEscapeCharacters();
		while (loop) {
			var c = read();
			if (c == "\\".code) {
				if (esc) {
					switch (read()) {
						case "x".code: pos += 2;
						case "u".code: pos += 4;
					}
				} else {
					if (peek() == "`".code) skip();
				}
			} else if (c == "`".code) {
				break;
			} else if (c == "$".code && peek() == "{".code) {
				skip();
				var depth = 0;
				while (loop) {
					c = read();
					switch (c) {
						case "{".code: depth++;
						case "}".code: {
							if (--depth < 0) break;
						};
						case "/".code: switch (peek()) {
							case "/".code: skipLine();
							case "*".code: skip(); skipComment();
							default:
						};
						case '"'.code, "'".code, "@".code, "`".code: {
							skipStringAuto(c, version);
						};
					}
				}
			} else if (c == "\n".code) n++;
		}
		return n;
	}
	
	public function skipNumber(canDot:Bool = true):Void {
		var c = peek();
		while (loopLocal) {
			if (c == ".".code) {
				if (canDot) {
					canDot = false;
					skip();
				} else break;
			} else if (c.isDigit()) {
				skip();
			} else break;
			c = peek();
		}
	}
	
	public function skipHex():Void {
		var c = peek();
		while (loopLocal) {
			if (c.isHex()) {
				skip();
				c = peek();
			} else break;
		}
	}
	
	public function skipStringAuto(startquote:CharCode, version:GmlVersion):Int {
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
					return skipStringTemplate(version);
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
	public function skipSpaces0() {
		while (loop) {
			switch (peek()) {
				case " ".code, "\t".code: {
					skip(); continue;
				};
			}; break;
		}
	}
	
	/** Skips spaces, tabs, `\r`, `\n` */
	public function skipSpaces1() {
		while (loop) {
			switch (peek()) {
				case " ".code, "\t".code, "\r".code, "\n".code: {
					skip(); continue;
				};
			}; break;
		}
	}
	
	public function skipSpaces1_local() {
		while (loopLocal) {
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
	
	public function skipIdent() {
		if (peek().isIdent0()) while (loopLocal) {
			if (peek().isIdent1()) {
				skip();
			} else break;
		}
	}
	
	public function skipIdent1() {
		while (loopLocal) {
			if (peek().isIdent1()) {
				skip();
			} else break;
		}
	}
	
	public function skipEventName() {
		while (loopLocal) {
			var c = peek();
			if (c.isIdent1() || c == ":".code) {
				skip();
			} else break;
		}
	}
	
	/** ("obj_some") this"#¦event step" -> "obj_some(step)" this"#event step¦" */
	public function readContextName(name:String) {
		var p = pos;
		skipIdent1();
		var preproc = substring(p - 1, pos);
		switch (preproc) {
			case "#define", "#event", "#moment", "#target": {
				skipSpaces0();
				p = pos;
				inline function next():String {
					return substring(p, pos);
				}
				switch (preproc) {
					case "#define", "#target": {
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
					default: {
						// todo: see if rewinding to orig-p is OK here
						return null;
					};
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
	public function skipVarExpr(v:GmlVersion, sep:CharCode):Int {
		var start = pos;
		var depth = 0;
		var n:Int = 0;
		while (pos < length) {
			var p = pos;
			var c:CharCode = read();
			if (c == sep && depth == 0) {
				pos = p;
				break;
			} else switch (c) {
				case " ".code, "\t".code, "\r".code:
				case "\n".code: n += 1;
				case "/".code: switch (peek()) {
					case "/".code: skipLine();
					case "*".code: skip(); skipComment();
					default:
				};
				case "(".code, "[".code, "{".code: depth += 1;
				case ")".code, "]".code, "}".code: depth -= 1;
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
	
	/**
	 * this"var a:Map¦<Int>" -> this"var a:Map<Int>¦"
	 * this"var a:Map¦<=" -> this"var a:Map¦<="
	 */
	public function skipTypeParams(?till:Int) {
		if (till == null) till = length;
		var p2 = pos;
		var depth = 1;
		skip();
		while (pos < till) {
			var c:CharCode = read();
			switch (c) {
				case " ".code, "\t".code: {};
				case "<".code: depth++;
				case ">".code: if (--depth <= 0) break;
				case ",".code: {};
				default: if (!c.isIdent1()) break;
			}
		}
		if (depth > 0) {
			pos = p2;
			return false;
		} else return true;
	}
	
	public function skipCommon_inline():Int {
		switch (peek()) {
			case "/".code: switch (peek(1)) {
				case "/".code: pos += 2; skipLine(); return 0;
				case "*".code: pos += 2; return skipComment();
				default: return -1;
			};
			case '"'.code, "'".code, "`".code, "@".code: {
				pos += 1;
				return skipStringAuto(peek(-1), version);
			};
			default: return -1;
		}
	}
	public function skipCommon():Int {
		return skipCommon_inline();
	}
	
	private static var rxVarType = new js.lib.RegExp("^" + GmlExtImport.rsLocalType + "$");
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
				if (pos > p1) {
					if (peek() == "<".code) skipTypeParams(till);
					d.type = substring(p1, pos);
				} else d.type = null;
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
				skipVarExpr(v, ",".code);
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
