package synext;
import tools.JsTools;
import js.lib.RegExp;
import parsers.GmlReader;
import tools.CharCode;
import tools.Dictionary;
import tools.NativeString;
import tools.NativeArray;
import ui.Preferences;
import gml.GmlAPI;
import synext.GmlExtArgsAce;

/**
 * Handles conversion from/to #args magic.
 * @author YellowAfterlife
 */
class GmlExtArgs {
	public static var errorText:String;
	
	/** subscript ("" for top) -> argument data; null on error */
	public static var argData:Dictionary<GmlExtArgData>;
	
	static function rxOpt_init() {
		var rx:RegExp;
		for (it in 0 ... 2) {
			var z = it > 0;
			var s1p = z ? "\\s+" : " ";
			var s1x = z ? "\\s*" : " ";
			var s0x = z ? "\\s*" : "";
			//
			var rsOpt0 = 'argument_count$s1x>$s1x(\\d+)';
			var rsOpt1 = 'argument$s0x\\[$s0x(\\d+)$s0x\\]';
			//
			rx = new RegExp("^var" + s1p + "(\\w+)" // -> name
			+ "(?:" + GmlExtImport.rsLocalType + ")?" // -> :type (opt.)
			+ "(?:" + s0x
				// `var q; if (argument_count > 3) q = argument[3]; else q = `
				+ ';${s1x}if$s1x\\($s0x$rsOpt0$s0x\\)$s1x' // `; if (argument_count > 3) `
				+ '(\\w+)$s1x=$s1x$rsOpt1$s0x;$s1x' // `q = argument[3]; `
				+ 'else$s1x(\\w+)$s1x=' // `else q = `
				// -> 
			+ '|' + s1x
				// `var q = argument_count > 3 ? argument[3] : `
				+ '=$s1x$rsOpt0$s1x\\?$s1x$rsOpt1$s1x\\:'
			+ ')$s1x([^;]+);', "g");
			if (!z) rxOptStrict = rx;
		}
		return rx;
	}
	private static var rxOptStrict:RegExp = null; // set by rxOpt_init
	private static var rxOpt:RegExp = rxOpt_init();
	private static inline var rxOpt_name = 1;
	private static inline var rxOpt_type = 2;
	private static inline var rxOpt_then = 3;
	private static inline var rxOpt_tern = 7;
	private static inline var rxOpt_value = 9;
	//
	static function rxGM8Req_init() {
		var rx:RegExp;
		for (it in 0 ... 2) {
			var lean = it > 0;
			var s1p = lean ? "\\s+" : " ";
			var s1x = lean ? "\\s*" : " ";
			var s0x = lean ? "\\s*" : "";
			//
			rx = new RegExp("^var" + s1p + "(\\w+)" // -> name
				+ "(?:" + GmlExtImport.rsLocalType + ")?" // -> :type (opt.)
				+ '(?:;${s1x}(\\w+))?'
				+ '${s1x}=${s1x}'
				+ 'argument(?:(\\d+)|$s0x\\[$s0x(\\d+)$s0x\\])' // -> index, index2
			+ ";", "");
			if (!lean) rxGM8Req_strict = rx;
		}
		return rx;
	}
	private static var rxGM8Req_strict:RegExp = null; // set by rxGM8Req_init
	private static var rxGM8Req:RegExp = rxGM8Req_init();
	private static inline var rxGM8Req_name1 = 1;
	private static inline var rxGM8Req_type = 2;
	private static inline var rxGM8Req_name2 = 3;
	private static inline var rxGM8Req_ind1 = 4;
	private static inline var rxGM8Req_ind2 = 5;
	
	private static var rxHasOpt = new RegExp('(?:\\?|=|,\\s*$)');
	private static var rxHasTail = new RegExp(',\\s*$');
	private static var rxNotMagic = new RegExp('var\\s+\\w+\\s*=\\s*'
		+ 'argument(?:\\s*\\[\\s*\\d+\\s*\\]|\\d+)', 'g');
	private static var argKeywords:Dictionary<Bool> = {
		var out = new Dictionary();
		out.set("argument", true);
		for (i in 0 ... 16) out.set("argument" + i, true);
		out;
	};
	public static function pre(code:String, ?strict:Bool):String {
		var version = GmlAPI.version;
		if (!Preferences.current.argsMagic) return code;
		if (strict == null) strict = Preferences.current.argsStrict;
		var hasFunctionLiterals = version.hasFunctionLiterals();
		var hasVarDeclSet = version.config.hasVarDeclSet;
		//
		var q = new GmlReader(code);
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		var rxOpt = strict ? rxOptStrict : rxOpt;
		var rxReq = hasVarDeclSet ? null : (strict ? rxGM8Req_strict : rxGM8Req);
		function proc() {
			var args = "#args";
			var argv = false;
			var found = 0;
			var pos:Int;
			var c:CharCode;
			var s:String;
			var spStart:Int;
			inline function qSkipSpaceStrict(n:Int):Bool {
				spStart = q.pos;
				q.skipSpaces0();
				return strict && (q.pos - spStart != n);
			}
			//
			pos = q.pos;
			q.skipLine();
			rxOpt.lastIndex = 0;
			var hasReq = hasVarDeclSet && !rxOpt.test(q.substring(pos, q.pos));
			q.pos = pos + (hasReq ? 3 : 0);
			// pass 1: required arguments (could do regexp..?)
			if (hasReq) while (q.loop) {
				//
				if (qSkipSpaceStrict(1)) return null;
				if (q.eof) return null;
				// match var name:
				pos = q.pos;
				c = q.peek();
				if (!c.isIdent0()) return null;
				q.skipIdent1();
				s = q.substring(pos, q.pos);
				// add to args:
				if (found > 0) args += ",";
				args += " " + s;
				//
				spStart = q.pos;
				q.skipSpaces0();
				// type?
				if (q.peek() == "/".code && q.peek(1) == "*".code) { // `var a/*:t*/`
					if (strict && q.pos != spStart) return null;
					var typePos = q.pos;
					q.skip(2);
					q.skipComment();
					var type = GmlExtImport.rxLocalType.exec(q.substring(typePos, q.pos));
					if (type != null) args += ":" + type[1];
					//
					q.skipSpaces0();
				} else if (q.peek() == ":".code) { // `var a:t`
					if (strict && q.pos != spStart) return null;
					var typePos = q.pos;
					q.skip();
					q.skipSpaces0();
					c = q.peek(); if (!c.isIdent0()) return null;
					q.skipIdent1();
					if (q.peek() == "<".code) { // `var a:T<...>`
						while (q.loop) if (q.read() == ">".code) break;
					}
					args += q.substring(typePos, q.pos);
					//
					q.skipSpaces0();
				} else {
					if (strict && q.pos != spStart + 1) return null;
				}
				// match `=`:
				if (q.eof || q.peek() != "=".code) return null;
				q.skip();
				// match `argument`:
				if (qSkipSpaceStrict(1)) return null;
				if (q.eof || q.peek() != "a".code) return null;
				pos = q.pos;
				q.skipIdent1();
				s = q.substring(pos, q.pos);
				if (s == "argument") { // match `argument[$i]`
					// `[`:
					if (qSkipSpaceStrict(0)) return null;
					if (q.eof || q.peek() != "[".code) return null;
					q.skip();
					// `$i`:
					if (qSkipSpaceStrict(0)) return null;
					if (q.eof) return null;
					pos = q.pos;
					q.skipIdent1();
					if (q.substring(pos, q.pos) != "" + found) return null;
					// `]`:
					if (qSkipSpaceStrict(0)) return null;
					if (q.eof || q.peek() != "]".code) return null;
					q.skip();
					//
					argv = true;
				} else {
					// match argument$i:
					if (s != "argument" + found) return null;
				}
				//
				found += 1;
				//
				q.skipSpaces0();
				if (q.eof) break;
				c = q.peek();
				switch (c) {
					case ",".code: q.skip();
					case ";".code: {
						q.skip();
						q.skipSpaces0();
						// do not allow #args with trailing data
						if (q.loopLocal && !q.peek().isSpace1()) return null;
						break;
					};
					default: if (c.isIdent0()) break; else return null;
				}
			}
			var till = q.pos;
			
			// pass 1a: required arguments (for GM versions without `var a = v`)
			if (!hasVarDeclSet) while (q.loop) {
				q.skipSpaces1();
				pos = q.pos;
				q.skipIdent1();
				s = q.substring(pos, q.pos);
				if (s != "var") { q.pos = till; break; }
				q.skipLine();
				var mt = rxReq.exec(q.substring(pos, q.pos));
				if (mt == null) { q.pos = till; break; }
				//
				var name = mt[rxGM8Req_name1];
				var name2 = mt[rxGM8Req_name2];
				if (name2 != null && name != name2) { q.pos = till; break; }
				//
				var argInd = JsTools.or(mt[rxGM8Req_ind1], mt[rxGM8Req_ind2]);
				if (argInd != "" + found) { q.pos = till; break; }
				//
				var type = mt[rxGM8Req_type];
				if (found > 0) args += ",";
				args += " " + name + (type != null ? ":" + type : "");
				found += 1;
				//
				till = q.pos;
			}
			
			// pass 2: optional arguments
			var req = found;
			while (q.loop) {
				q.skipSpaces1();
				pos = q.pos;
				q.skipIdent1();
				s = q.substring(pos, q.pos);
				if (s != "var") { q.pos = till; break; }
				q.skipLine();
				rxOpt.lastIndex = 0;
				var mt = rxOpt.exec(q.substring(pos, q.pos));
				if (mt == null) { q.pos = till; break; }
				q.pos = pos + rxOpt.lastIndex;
				//
				var name = mt[rxOpt_name];
				var type:Null<String> = mt[rxOpt_type];
				var foundStr = "" + found;
				if (mt[rxOpt_then] != null
					? (mt[rxOpt_then] != foundStr || mt[rxOpt_then + 1] != name
					|| mt[rxOpt_then + 2] != foundStr || mt[rxOpt_then + 3] != name)
					: (mt[rxOpt_tern] != foundStr || mt[rxOpt_tern + 1] != foundStr)
				) { q.pos = till; break; }
				//
				var val = mt[rxOpt_value];
				if (found > 0) args += ",";
				var isOpt:Bool = (val == "undefined");
				args += (isOpt ? " ?" : " ") + name + (type != null ? ":" + type : "")
					+ (isOpt ? "" : " = " + val);
				found += 1;
				//
				till = q.pos;
			}
			if (req == found && argv) args += ",";
			//
			if (!hasFunctionLiterals) {
				var trailEnd = code.indexOf("\n#define", q.pos);
				var trailCode:String;
				if (trailEnd >= 0) {
					trailCode = code.substring(q.pos, trailEnd);
				} else trailCode = code.substring(q.pos);
				rxNotMagic.lastIndex = 0;
				if (rxNotMagic.test(trailCode)) {
					//q.pos = proc_start;
					return null;
				}
			}
			//
			if (args == "#args") return null;
			return args;
		}
		//
		var curlyDepth = 0;
		var checkArgs = true;
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				case "$".code if (q.isDqTplStart(version)): q.skipDqTplString(version);
				case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
					if (q.substring(p, p + 7) == "#define") {
						checkArgs = true; 
					}
				};
				case "{".code: curlyDepth++;
				case "}".code: curlyDepth--;
				default: {
					if (checkArgs && c.isIdent0()) {
						q.skipIdent1();
						var id = q.substring(p, q.pos);
						if (id == "var") {
							var p1 = q.pos;
							q.pos = p;
							var s = proc();
							if (s != null) {
								flush(p);
								out += s;
								start = q.pos;
								checkArgs = false;
							} else {
								// if we don't find #args, revert reading position to var|
								q.pos = p1;
							}
						}
						else if (hasFunctionLiterals && id == "function") {
							checkArgs = true;
						}
						else if (argKeywords[id]) {
							// if we find a argument#/argument[#] before #args line, it's not that.
							checkArgs = false;
						}
					} else if (hasFunctionLiterals && c == "f".code) {
						q.skipIdent1();
						if (q.substring(p, q.pos) == "function") {
							checkArgs = true;
						}
					}
				};
			}
		}
		flush(q.pos);
		return out;
	}
	public static function post(code:String):Null<String> {
		var version = GmlAPI.version;
		var hasVarDeclSet = version.config.hasVarDeclSet;
		var hasTernary = version.hasTernaryOperator();
		//
		argData = null;
		if (!Preferences.current.argsMagic || code.indexOf("#args") < 0) return code;
		var data = new Dictionary();
		var argNames:Array<String> = [];
		var argTypes:Array<String> = [];
		var argTexts:Array<String> = [];
		var curr:GmlExtArgData = { names: argNames, texts: argTexts, types: argTypes };
		data.set("", curr);
		//
		var q = new GmlReader(code);
		var row = 0;
		var out = "";
		var start = 0;
		function flush(till:Int) {
			out += q.substring(start, till);
		}
		inline function error(s:String) {
			errorText = '[row $row]: ' + s;
			return true;
		}
		function proc() {
			var reqDone = null;
			var found = 0;
			//
			var p = q.pos;
			q.skipLine();
			var line = q.substring(p, q.pos);
			var hasTail = rxHasTail.test(line);
			var hasOpt = hasTail || rxHasOpt.test(line);
			q.pos = p;
			//
			while (q.loop) {
				q.skipSpaces0();
				//
				var val:String, set:String = " = ";
				var docName = "";
				var docText = "";
				if (q.peek() == "?".code) {
					q.skip();
					q.skipSpaces0();
					val = "undefined";
					docName += "?";
				} else val = null;
				//
				p = q.pos;
				q.skipIdent1();
				var name = q.substring(p, q.pos);
				var type = "", docType:String = "";
				if (name == "") return error("Expected an argument name");
				docName += name;
				//
				p = q.pos;
				q.skipSpaces0();
				if (q.peek() == ":".code) {
					q.skip();
					q.skipSpaces0();
					var typePos = q.pos;
					q.skipIdent1();
					if (q.pos > typePos) {
						if (q.peek() == "<".code) q.skipTypeParams();
						docType = q.substring(typePos, q.pos);
						type = "/*:" + docType + "*/";
						q.skipSpaces0();
					}
				}
				if (q.peek() == "=".code) {
					if (val != null) return error('?$name means that default value is undefined, why assign another default value after that');
					q.skip();
					q.skipSpaces0();
					set = q.substring(p, q.pos);
					//
					p = q.pos;
					var depth = 0;
					while (q.loop) {
						var c = q.read();
						switch (c) {
							case "/".code: switch (q.peek()) {
								case "/".code: q.skipLine();
								case "*".code: q.skip(); row += q.skipComment();
								default:
							};
							case '"'.code, "'".code, "`".code, "@".code: row += q.skipStringAuto(c, version);
							case "$".code if (q.isDqTplStart(version)): row += q.skipDqTplString(version);
							case "(".code, "[".code, "{".code: depth += 1;
							case ")".code, "]".code, "}".code: depth -= 1;
							case ",".code: if (depth <= 0) { q.pos -= 1; break; }
							case "\r".code, "\n".code: q.pos -= 1; break;
							default:
						}
					}
					if (depth != 0) return error('Unbalanced expression for value of $name');
					val = q.substring(p, q.pos);
				}
				//
				if (val != null) {
					docText = "= " + val;
					if (reqDone == false) {
						reqDone = true;
						out += ";\r\n";
					}
					if (hasTernary) {
						out += 'var $name$type = argument_count > $found'
							+ ' ? argument[$found] : $val;\r\n';
					} else {
						out += 'var $name$type; if (argument_count > $found)'
							+ ' $name = argument[$found]; else $name = $val;\r\n';
					}
				} else if (hasVarDeclSet) {
					if (reqDone) return error('Can\'t have required arguments after optional arguments.');
					reqDone = false;
					if (found == 0) {
						out += "var ";
					} else if (found > 0) out += ", ";
					out += '$name$type = argument' + (hasOpt ? '[$found]' : "" + found);
				} else { // gm8
					out += ('var $name$type; $name = argument'
						+ (hasOpt ? '[$found]' : "" + found)
						+ ";\r\n"
					);
				}
				argNames.push(docName);
				argTypes.push(docType);
				argTexts.push(docText);
				found += 1;
				q.skipSpaces0();
				if (q.loop) switch (q.peek()) {
					case ",".code: {
						q.skip();
						q.skipSpaces0();
						switch (q.peek()) {
							case "\r".code, "\n".code: q.skipLineEnd(); break;
						}
					};
					case "\r".code, "\n".code: q.skipLineEnd(); break;
					default: return error('Expected a comma or end of line after $name');
				}
			}
			if (hasTail) {
				argNames.push("...");
				argTypes.push("");
				argTexts.push("");
			}
			if (found > 0 && reqDone == false) out += ";\r\n";
			return false;
		}
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); row += q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: row += q.skipStringAuto(c, version);
				case "$".code if (q.isDqTplStart(version)): row += q.skipDqTplString(version);
				case "#".code: {
					if (q.substring(p, p + 5) == "#args") {
						flush(p);
						q.pos += 4;
						if (proc()) return null;
						start = q.pos;
					} else if ((p == 0 || q.get(p - 1) == "\n".code)
						&& q.substring(p, p + 7) == "#define"
					) {
						// context switch
						flush(p);
						start = p;
						q.pos += 6;
						q.skipSpaces0();
						p = q.pos;
						q.skipIdent1();
						//
						argNames = [];
						argTypes = [];
						argTexts = [];
						curr = { names: argNames, texts: argTexts, types: argTypes };
						data.set(q.substring(p, q.pos), curr);
						//
						q.skipLine();
					}
				};
			}
		}
		flush(q.pos);
		argData = data;
		return out;
	}
}
typedef GmlExtArgData = {
	names:Array<String>,
	types:Array<String>,
	texts:Array<String>,
};
