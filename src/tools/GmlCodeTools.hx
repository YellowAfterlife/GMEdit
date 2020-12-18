package tools;
import gml.Project;
import parsers.GmlReader;
import tools.Aliases;
import tools.CharCode;
using StringTools;

/**
 * Some of these come from GMVitalizer
 * https://github.com/YellowAfterlife/GMVitalizer
 * @author YellowAfterlife
 */
class GmlCodeTools {
	private static function mapKws(kws:Array<String>):Map<String, Bool> {
		var result = new Map();
		for (kw in kws) result[kw] = true;
		return result;
	}
	
	/** `ident ident` breaks expression unless it's `op ident` or `ident op` */
	public static var operatorKeywords:Map<String, Bool> = mapKws([
		"not", "and", "or", "xor", "div", "mod"
	]);
	
	/** These definitely end expressions */
	public static var statementKeywords:Map<String, Bool> = mapKws([
		"var", "globalvar",
		"if", "then", "else",
		"for", "while", "do", "until", "repeat", "break", "continue",
		"switch", "case", "default",
		"exit", "return",
		"try", "catch", "throw", "function",
	]);
	
	/**
	 * `if (_) obj¦.fd = 1;` -> `if (_) ¦obj.fd = 1;`
	 */
	public static function skipDotExprBackwards(src:GmlCode, pos:StringPos):StringPos {
		var depth = 0;
		var len = src.length;
		while (--pos >= 0) {
			var till = pos + 1;
			var c:CharCode = src.fastCodeAt(pos);
			switch (c) {
				case '"'.code: {
					while (--pos >= 0) {
						c = src.fastCodeAt(pos);
						if (c == '"'.code) {
							if (src.fastCodeAt(pos - 1) != "\\".code) break;
						}
					}
					if (depth == 0) return pos;
				};
				/*case VitGML.commentEOL: {
					if (depth <= 0) return till;
					while (--pos >= 0) {
						if (src.fastCodeAt(pos) == "/".code
							&& src.fastCodeAt(pos - 1) == "/".code
						) pos--;
					}
				};*/
				case ")".code, "]".code, "}".code: depth++;
				case "[".code: depth--;
				case "(".code, "{".code: if (--depth <= 0) {
					return pos;
				};
				case _ if (c.isIdent1()): {
					while (pos > 0) {
						c = src.fastCodeAt(pos - 1);
						if (c.isIdent1()) {
							pos--;
						} else break;
					}
					var id = src.substring(pos, till);
					var np = pos;
					while (--np >= 0) {
						c = src.fastCodeAt(np);
						if (!c.isSpace0()) break;
					}
					if (src.fastCodeAt(np) == ".".code) {
						// `?.` is only used in null coalesce but I don't want to add flags right now
						if (src.fastCodeAt(np - 1) == "?".code) np--;
						pos = np;
					} else if (depth == 0) {
						return pos;
					}
				};
				case _ if (c.isSpace1()): {};
				case _ if (depth == 0): {
					while (till < len) {
						c = src.fastCodeAt(till);
						if (c.isSpace0()) till++; else break;
					}
					return till;
				};
			}
		}
		return 0;
	}
	
	/** `a.¦b` -> true */
	public static function isDotAccessBacktrack(src:GmlCode, pos:StringPos):Bool {
		while (--pos >= 0) {
			var c:CharCode = src.fastCodeAt(pos);
			switch (c) {
				case ".".code: return true;
				case _ if (c.isSpace1()): {};
				default: return false;
			}
		}
		return false;
	}
	
	/**
	 * `if (_) ¦` -> true, `if (a || ¦b)` -> false, etc.
	 * @param isInline whether the source string represents an inline expression
	 */
	public static function isStatementBacktrack(src:GmlCode, pos:StringPos, isInline:Bool):Bool {
		while (--pos >= 0) {
			var c:CharCode = src.fastCodeAt(pos);
			switch (c) {
				case '"'.code, "'".code: return true;
				case ")".code, "]".code, "{".code, "}".code: return true;
				case "[".code: return false;
				case "(".code: { // only `for (` is OK
					while (--pos >= 0) {
						c = src.fastCodeAt(pos);
						if (c.isSpace0()) continue;
						return pos >= 3 && c == "r".code
							&& src.fastCodeAt(pos - 1) == "o".code
							&& src.fastCodeAt(pos - 2) == "f".code
							&& (pos == 3 || !(src.fastCodeAt(pos - 3):CharCode).isIdent1_ni());
					}
					return true;
				};
				case "+".code, "-".code: {
					if (src.fastCodeAt(--pos) == c) { //++thing?
						// keep going
					} else return false;
				};
				case ",".code: {
					// it could be a variable declaration, but we don't usually remap those
					return false;
				};
				case "/".code: {
					if (src.fastCodeAt(--pos) == "*".code) { // comment
						pos--;
						while (--pos >= 0) {
							if (src.fastCodeAt(pos) == "*".code
								&& src.fastCodeAt(pos - 1) == "/".code
							) {
								pos--;
							}
						}
					} else return false;
				};
				/*case VitGML.commentEOL: {
					while (--pos >= 0) {
						if (src.fastCodeAt(pos) == "/".code
							&& src.fastCodeAt(pos - 1) == "/".code
						) {
							pos--;
						}
					}
				};*/
				case"|".code, "^".code, "&".code,
					"*".code, "%".code,
					">".code, "<".code,
				"=".code: return false; // def. operators
				case _ if (c.isIdent1()): {
					var till = pos + 1;
					while (pos > 0) {
						if ((src.fastCodeAt(pos - 1):CharCode).isIdent1()) pos--; else break;
					}
					var id = src.substring(pos, till);
					return switch (id) {
						case "if", "while", "until", "repeat", "switch", "case", "return": false;
						default: !operatorKeywords[id];
					}
				};
			}
		}
		return !isInline;
	}
	
	/**
	 * Returns whether the expression is being written (true) or read (false)
	 * `a = {p0}v{p1} + 1;` -> false
	 * `{p0}v{p1} = 1;` -> true
	 * `++{p0}v{p1}` -> true
	 * Checks both forward and by backtracking
	 */
	public static function isWrite(code:GmlCode, p0:Int, p1:Int):Bool {
		// prefix:
		var isStat:Bool = true;
		while (--p0 >= 0) switch (code.fastCodeAt(p0)) {
			case " ".code, "\t".code, "\r".code, "\n".code: { };
			case "+".code: if (code.fastCodeAt(--p0) == "+".code) return true; else break;
			case "-".code: if (code.fastCodeAt(--p0) == "-".code) return true; else break;
			case "[".code: return false;
			default: {
				isStat = isStatementBacktrack(code, p0 + 1, false);
				break;
			}
		}
		// postfix/setop:
		while (p1 < code.length) switch (code.fastCodeAt(p1++)) {
			case " ".code, "\t".code, "\r".code, "\n".code: { };
			case "=".code: return code.fastCodeAt(p1) != "=".code && isStat;
			case "+".code: switch (code.fastCodeAt(p1)) {
				case "+".code, "=".code: return true;
				default: return false;
			};
			case "-".code: switch (code.fastCodeAt(p1)) {
				case "-".code, "=".code: return true;
				default: return false;
			};
			case "*".code, "/".code, "%".code, "^".code, "|".code, "&".code: {
				return code.fastCodeAt(p1) == "=".code;
			};
			default: return false;
		}
		return false;
	}
	
	public static function getReferenceKind(code:GmlCode, p0:StringPos, p1:StringPos, ?q:GmlReader):GmlReferenceKind {
		var p0_orig = p0;
		var p1_orig = p1;
		var c:CharCode;
		var version = q != null ? q.version : Project.current.version;
		//
		while (p0 > 0) {
			c = code.fastCodeAt(p0 - 1);
			switch (c) {
				case ".".code: {
					p0 = skipDotExprBackwards(code, p0 - 1);
					break;
				};
				case "r".code if (p0 >= 3
					&& code.fastCodeAt(p0 - 2) == "a".code
					&& code.fastCodeAt(p0 - 3) == "v".code
				): {
					if (p0 == 3) return Declaration;
					c = code.fastCodeAt(p0 - 4);
					if (!c.isIdent0()) return Declaration;
					if (c == "l".code && p0 >= 9 && code.substring(p0 - 9, p0 - 3) == "global") {
						if (p0 == 9) return Declaration;
						c = code.fastCodeAt(p0 - 10);
						if (!c.isIdent0()) return Declaration;
					}
					break;
				};
				case "o".code if (p0 >= 6
					&& code.fastCodeAt(p0 - 6) == "#".code
					&& code.substring(p0 - 6, p0) == "#macro"
				): return Declaration;
				case _ if (c.isSpace1()): p0--;
				default: break;
			}
		}
		//
		while (p1 < code.length) {
			c = code.fastCodeAt(p1);
			if (c.isSpace1()) p1++; else break;
		}
		//
		switch (code.fastCodeAt(p1)) {
			case "[".code: {
				if (q == null) q = new GmlReader(code, version);
				q.pos = p1;
				var depth = 0;
				while (q.loopLocal) {
					c = q.read();
					switch (c) {
						case "[".code: depth++;
						case "]".code: if (--depth <= 0) break;
						case "/".code: switch (q.peek()) {
							case "/".code: q.skipLine();
							case "*".code: q.skip(); q.skipComment();
							default:
						};
						case '"'.code, "'".code, "`".code, "@".code: {
							q.skipStringAuto(c, version);
						};
						default:
					}
				}
				return isWrite(code, p0, q.pos) ? ArrayWrite : ArrayRead;
			};
			case "(".code: return Call;
			default: {
				return isWrite(code, p0, p1) ? Write : Read;
			}
		}
	}
}
enum abstract GmlReferenceKind(String) {
	var Read = "r";
	var Write = "w";
	var Call = "c";
	var Declaration = "d";
	var ArrayRead = "ar";
	var ArrayWrite = "aw";
	public inline function toShortString():String {
		return this;
	}
	public inline function fromShortString(s:String):GmlReferenceKind {
		return cast s;
	}
	public function toFullString():String {
		switch (fromShortString(this)) {
			case Read: return "read";
			case Write: return "write";
			case Call: return "call";
			case Declaration: return "declaration";
			case ArrayRead: return "array-read";
			case ArrayWrite: return "array-write";
			default: return "???" + this;
		}
	}
}