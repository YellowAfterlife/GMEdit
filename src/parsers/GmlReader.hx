package parsers;

import ace.extern.*;
import file.FileKind;
import file.kind.gml.KGmlScript;
import gml.type.GmlType;
import gml.GmlVersion;
import gml.type.GmlTypeDef;
import synext.GmlExtImport;
import tools.Aliases;
import tools.CharCode;
import tools.StringReader;
using tools.NativeString;

/**
 * Extends regular string parser with a set of GML-related helpers.
 * @author YellowAfterlife
 */
@:keep class GmlReader extends StringReader {
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
						case "\n".code: n++;
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

	/** Reads a number*/
	public function readNumber():String {
		var start = pos;
		skipNumber();
		return substring(start,pos);
	}

	
	/**Skips the remainder of an already opened hex*/
	public function skipHex():Void {
		var c = peek();
		while (loopLocal) {
			if (c.isHex()) {
				skip();
				c = peek();
			} else break;
		}
	}

	/** Reads the remainder of an already opened hex*/
	public function readHex():String {
		var start = pos;
		skipHex();
		return substring(start,pos);
	}
	
	/** Reads the remainder of an already opened string */
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

	public function readStringAuto(startquote:CharCode):String {
		var start = pos;
		skipStringAuto(startquote, version);
		return substring(start, pos-1); // -1 because pos went past the quote
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
	
	public function skipSpaces0_local() {
		while (loopLocal) {
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
		if (peek().isIdent0()) inline skipIdent1();
	}
	
	public function skipIdent1() {
		while (loopLocal) {
			if (peek().isIdent1()) {
				skip();
			} else break;
		}
	}
	
	/**
	 * Reads a word and returns it.
	 * Returns null if the cursor was not at a word.
	 * `+ ¦a;` -> "a", `+ a¦;`
	 * `+¦ a;` -> null, `+¦ a;`
	 */
	public function readIdent():String {
		if (!peek().isIdent0()) return null;
		var start = pos;
		inline skipIdent1();
		return substring(start, pos);
	}
	
	public function skipEventName() {
		while (loopLocal) {
			var c = peek();
			if (c.isIdent1() || c == ":".code) {
				skip();
			} else break;
		}
	}
	
	public inline function canContextName(p:Int) {
		return p == 0 || get(p - 1) == "\n".code;
	}
	
	/** ("obj_some") this"#¦event step" -> "obj_some(step)" this"#event step¦" */
	public function readContextName(name:String) {
		var p = pos;
		skipIdent1();
		var preproc = substring(p - 1, pos);
		var result:String;
		inline function proc(fn:Void->Void):Void {
			skipSpaces0();
			p = pos;
			fn();
			result = substring(p, pos);
			skipLine();
		}
		switch (preproc) {
			case "#define", "#target":
				proc(function() skipIdent1());
				return result;
			case "#event":
				proc(function() skipEventName());
				return name != null ? name + '($result)' : result;
			case "#moment":
				proc(function() skipIdent1());
				return name != null ? name + '($result)' : result;
			default:
				// todo: see if rewinding to orig-p is OK here
				return null;
		}
	}
	
	public function canHaveTopLevelFunctions(kind:FileKind) {
		var pj = gml.Project.current;
		if (version == pj.version) {
			if (!pj.isGMS23) return false;
		} else {
			if (!version.hasFunctionLiterals()) return false;
		}
		if (!Std.is(kind, KGmlScript)) return false;
		return (cast kind:KGmlScript).isScript;
	}
	
	public function readSolFunctionName():String {
		if (pos > 0 && peek(-1) != "\n".code) return null;
		return inline readFunctionName();
	}
	
	/**
	 * `¦function name() {}` -> "name", `function name¦() {}`
	 * `¦function() {}` -> null, `¦function() {}`
	 */
	public function readFunctionName(?first:CharCode):String {
		var start = pos;
		var at = pos;
		if (first == null) {
			first = peek();
		} else at--;
		//
		if (first != "f".code) return null;
		if (get(at + 7) != "n".code) return null;
		var c = get(at + 8); if (c.isIdent1()) return null;
		if (substr(at, 8) != "function") return null;
		//
		pos = at + 8;
		skipSpaces0_local();
		c = peek(); if (!c.isIdent0()) { pos = start; return null; }
		start = pos;
		skipIdent1();
		return substring(start, pos);
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

	public function skipNopsTillNewline() {
		while (pos < length) {
			var c = peek();
			switch (c) {
				case " ".code, "\t".code, "\r".code: skip();
				case "\n".code: skip(); return;
				case "/".code: switch (peek(1)) {
					case "/".code: skipLine();
					case "*".code: skip(2);
					default: break;
				};
				default: break;
			}
		}
		return;
	}

	/** Reads comments and whitespace*/
	public function readNops():String {
		var start = pos;
		skipNops();
		return substring(start, pos);
	}

	/** Reads comments and whitespace until it encounters a new line*/
	public function readNopsTillNewline():String {
		var start = pos;
		skipNopsTillNewline();
		return substring(start, pos);
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
	public function skipTypeParams(?till:Int):Success {
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
				case ",".code, ";".code: {};
				default: if (!c.isIdent1()) break;
			}
		}
		if (depth > 0) {
			pos = p2;
			return false;
		} else return true;
	}
	
	public function skipType(?till:Int):Success {
		// also see GmlTypeParser.parseRec, GmlLinter.readTypeName
		if (till == null) till = length;
		var start = pos;
		inline function rewind():Success {
			pos = start;
			return false;
		}
		skipSpaces1x(till);
		var c = read();
		switch (c) {
			case "(".code:
				if (!skipType(till)) return rewind();
				skipSpaces1x(till);
				if (read() != ")".code) return rewind();
			case _ if (c.isIdent0()):
				skipIdent1();
				start = pos;
				skipSpaces1x(till);
				if (peek() == "<".code) {
					skip();
					if (!skipTypeParams(till)) return rewind();
				} else pos = start;
			default: return rewind();
		}
		//
		start = pos;
		while (loop) {
			skipSpaces1x(till);
			switch (peek()) {
				case "[".code if (peek(1) == "]".code): skip(2);
				case "?".code: skip();
				case "|".code:
					skip();
					if (!skipType(till)) return rewind();
				default: break;
			}
			start = pos;
		}
		pos = start;
		return true;
	}
	
	/** Skips comments and strings. Returns >= 0 if something was skipped, -1 otherwise. */
	public function skipCommon_inline():Int {
		var c = peek();
		switch (c) {
			case "/".code: switch (peek(1)) {
				case "/".code: pos += 2; skipLine(); return 0;
				case "*".code: pos += 2; return skipComment();
				default: return -1;
			};
			case '"'.code, "'".code, "`".code, "@".code: {
				pos += 1;
				return skipStringAuto(c, version);
			};
			default: return -1;
		}
	}
	public function skipCommon():Int {
		return skipCommon_inline();
	}
	
	/** `fn(¦a, b);` -> true, `fn(a, b)¦;` */
	public function skipBalancedParenExpr():Bool {
		var depth = 0;
		while (loop) {
			var c = read();
			switch (c) {
				case "/".code: switch (peek()) {
					case "/".code: skipLine();
					case "*".code: skip(); skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: skipStringAuto(c, version);
				case "(".code, "[".code, "{".code: depth++;
				case ")".code, "]".code, "}".code: if (--depth < 0) return true;
				default: 
			}
		}
		return false;
	}
	
	private static var rxVarType = new js.lib.RegExp("^" + GmlExtImport.rsLocalType + "$");
	public function skipVars(fn:SkipVarsData->Void, v:GmlVersion, isArgs:Bool):Int {
		var n = 0;
		var d:SkipVarsData = { // NB! this is getting reused
			name: null, name0: 0, name1: 0,
			type: null, type0: 0, type1: 0, typeStr: null,
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
				skip();
				var p1 = pos;
				skipType();
				if (pos > p1) {
					d.typeStr = substring(p1, pos);
					d.type = GmlTypeDef.parse(d.typeStr);
				} else d.type = null;
			} else if (peek() == "/".code && peek(1) == "*".code && peek(2) == ":".code) {
				skip(3);
				var cmtStart = pos;
				skipComment();
				var cmtEnd = pos;
				pos = cmtStart;
				skipType();
				skipSpaces1x(cmtEnd);
				if (pos == cmtEnd - 2) {
					d.typeStr = substring(cmtStart, cmtEnd - 2);
					d.type = GmlTypeDef.parse(d.typeStr);
				} else {
					d.type0 = cmtEnd;
					d.typeStr = null;
					d.type = null;
				}
				pos = cmtEnd;
			} else {
				d.typeStr = null;
				d.type = null;
			}
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
	 * Returns whether the expression is being written (true) or read (false)
	 * `a = {p0}v{p1} + 1;` -> false
	 * `{p0}v{p1} = 1;` -> true
	 * `++{p0}v{p1}` -> true
	 * Checks both forward and by backtracking
	 */
	public function checkWrites(p0:Int, p1:Int) {
		return tools.GmlCodeTools.isWrite(source, p0, p1);
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
	type:GmlType, type0:Int, type1:Int, typeStr:String,
	expr0:Int, expr1:Int, opt:Bool,
};
