package gml;
import js.lib.RegExp;
import parsers.GmlReader;
import tools.CharCode;
import tools.Aliases;
using StringTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFuncDoc {
	
	public var name:String;
	
	/** "func(" */
	public var pre:String;
	
	/** "): doc" */
	public var post:String;
	
	/** an array of argument names */
	public var args:Array<String>;
	
	public var hasReturn:Bool = null;
	
	/**
	 * Whether this is a 2.3 `function(...) constructor`
	 * (implications: should only be called via `new`, does not need to return)
	 */
	public var isConstructor:Bool = false;
	
	var minArgsCache:Null<Int> = null;
	
	static var rxIsOpt:RegExp = new RegExp("^\\s*(?:"
		+ "\\[" // [arg]
		+ "|\\?" // ?arg
		+ "|\\.\\.\\." // ...rest
	+ ")");
	public var minArgs(get, never):Int;
	private function get_minArgs():Int {
		if (minArgsCache != null) return minArgsCache;
		var argi = args.length;
		while (argi > 0) {
			var arg = args[argi - 1];
			if (arg == null
				|| rxIsOpt.test(arg)
				|| arg.endsWith("*")
				|| arg.contains("=")
				|| arg.contains("optional")
			) {
				argi--;
			} else if (arg.contains("]") && !arg.contains("[")) {
				// camera_create_view(room_x, room_y, width, height, [angle, object, x_speed, y_speed, x_border, y_border])
				var argk = argi;
				while (--argk >= 0) {
					if (args[argk].contains("[")) break;
				}
				if (argk < 0) break; else argi = argk;
			} else break;
		}
		minArgsCache = argi;
		return minArgsCache;
	}
	
	public var maxArgs(get, never):Int;
	private function get_maxArgs():Int {
		return rest ? 0x7fffffff : args.length;
	}
	
	/** whether to show "..." in the end of argument list */
	public var rest:Bool;
	
	/** Whether this is an incomplete/accumulating doc */
	public var acc:Bool = false;
	
	public function new(name:String, pre:String, post:String, args:Array<String>, rest:Bool) {
		this.name = name;
		this.pre = pre;
		this.post = post;
		this.args = args;
		this.rest = rest;
	}
	
	public function clear():Void {
		post = ")";
		args.resize(0);
		rest = false;
		acc = false;
		minArgsCache = null;
	}
	
	public function getAcText() {
		return pre + args.join(", ") + post;
	}
	
	public static function parse(s:String, ?out:GmlFuncDoc):GmlFuncDoc {
		var p0 = s.indexOf("(");
		var p1 = s.indexOf(")", p0);
		var name:String, pre:String, post:String, args:Array<String>, rest:Bool;
		if (p0 >= 0 && p1 >= 0) {
			name = s.substring(0, p0);
			var sw = s.substring(p0 + 1, p1).trimBoth();
			pre = s.substring(0, p0 + 1);
			post = s.substring(p1);
			if (sw != "") {
				args = sw.splitReg(js.Syntax.code("/,\\s*/g"));
			} else args = [];
			rest = sw.indexOf("...") >= 0;
		} else {
			name = s;
			pre = s;
			post = "";
			args = [];
			rest = false;
		}
		if (out != null) {
			out.minArgsCache = null;
			out.name = name;
			out.pre = pre;
			out.post = post;
			out.args = args;
			out.rest = rest;
			return out;
		} else return new GmlFuncDoc(name, pre, post, args, rest);
	}
	
	static var fromCode_rx:RegExp = new RegExp("\\bargument(?:"
		+ "(\\d+)" // argument0
		+ "|\\s*\\[\\s*(?:(\\d+)\\s*\\])?" // argument[0] | argument[???]
	+ ")", "g");
	static var fromCode_hasRet:RegExp = new RegExp("\\breturn\\b\\s*[^;]");
	private static function fromCode_skipArgCountCmp(chunk:GmlCode, k:Int):Int {
		var c:CharCode;
		// `name = argument_count > 1[ ]? argument[1]`
		while (--k >= 0) {
			c = chunk.fastCodeAt(k);
			if (!c.isSpace1()) break;
		}
		// `name = argument_count > [1] ? argument[1]`
		c = chunk.fastCodeAt(k);
		if (!c.isDigit()) return -1;
		while (--k >= 0) {
			c = chunk.fastCodeAt(k);
			if (!c.isDigit()) break;
		}
		// `name = argument_count >[ ]1 ? argument[1]`
		while (k >= 0) {
			c = chunk.fastCodeAt(k);
			if (c.isSpace1()) k--; else break;
		}
		// `name = argument_count [>] 1 ? argument[1]`
		if (chunk.fastCodeAt(k) == "=".code) k--;
		if (chunk.fastCodeAt(k) == ">".code) k--; else return -1;
		// `name = argument_count[ ]> 1 ? argument[1]`
		while (k >= 0) {
			c = chunk.fastCodeAt(k);
			if (c.isSpace1()) k--; else break;
		}
		// `name = [argument_count] > 1 ? argument[1]`
		var acEnd = k + 1;
		if (chunk.fastCodeAt(k) != "t".code) return -1;
		while (--k >= 0) {
			c = chunk.fastCodeAt(k);
			if (!c.isIdent1()) break;
		}
		if (acEnd - k != 15 || chunk.substring(k + 1, acEnd) != "argument_count") return -1;
		// `name =[ ]argument_count > 1 ? argument[1]`
		while (k >= 0) {
			c = chunk.fastCodeAt(k);
			if (c.isSpace1()) k--; else break;
		}
		//
		return k;
	}
	private static function fromCode_skipIf(chunk:GmlCode, k:Int):Int {
		var c:CharCode;
		// `if (argument_count > 1)[ ]some = argument[1]`
		while (k >= 0) {
			c = chunk.fastCodeAt(k);
			if (c.isSpace1()) k--; else break;
		}
		// `if (argument_count > 1[)] some = argument[1]`
		if (chunk.fastCodeAt(k) != ")".code) return -1;
		k = fromCode_skipArgCountCmp(chunk, k);
		if (k < 0) return -1;
		// `if [(]argument_count > 1) some = argument[1]`
		if (chunk.fastCodeAt(k) == "(".code) k--; else return -1;
		// `if[ ](argument_count > 1) some = argument[1]`
		while (k >= 0) {
			c = chunk.fastCodeAt(k);
			if (c.isSpace1()) k--; else break;
		}
		// `[if] (argument_count > 1) some = argument[1]`
		var acEnd = k + 1;
		if (chunk.fastCodeAt(k) == "f".code) k--; else return -1;
		if (chunk.fastCodeAt(k) == "i".code) k--; else return -1;
		if ((chunk.fastCodeAt(k):CharCode).isIdent1_ni()) return -1;
		//
		return k;
	}
	
	static var nameTrimPattern:String = null;
	static var nameTrimRegex:RegExp = null;
	public function fromCode(gml:String, from:Int = 0, ?_till:Int) {
		var q = new GmlReader(gml);
		var rx = fromCode_rx;
		q.pos = from;
		var start = from;
		var till:Int = _till != null ? _till : gml.length;
		clear();
		//
		{ // sync regex
			var pt = Project.current.properties.argNameRegex;
			if (pt != nameTrimPattern) {
				nameTrimPattern = pt;
				nameTrimRegex = null;
				if (pt != null) try {
					nameTrimRegex = new RegExp(pt);
				} catch (x:Dynamic) {
					Main.console.error('Error compiling `$pt`:', x);
				}
			}
		};
		var ntrx = nameTrimRegex;
		//
		var hasRet = false;
		var hasRetRx = fromCode_hasRet;
		function flush(p:Int):Void {
			var chunk = q.substring(start, p);
			rx.lastIndex = 0;
			var mt = rx.exec(chunk);
			var c:CharCode;
			if (!hasRet && hasRetRx.test(chunk)) hasRet = true;
			while (mt != null) {
				var argis = tools.JsTools.or(mt[1], mt[2]);
				if (argis != null) {
					var argi:Int = Std.parseInt(argis);
					var k = mt.index;
					// see if argument is being assigned somewhere
					var hasSet = false;
					var isOpt = false;
					while (--k >= 0) {
						c = chunk.fastCodeAt(k);
						if (c.isSpace1()) continue;
						if (c == "?".code) { // perhaps `name = argument_count > 1 ? argument[1]`?
							hasSet = false;
							var k1 = fromCode_skipArgCountCmp(chunk, k);
							if (k1 >= 0) {
								k = k1;
								c = chunk.fastCodeAt(k);
								isOpt = true;
							}
						}
						hasSet = (c == "=".code && chunk.fastCodeAt(k - 1) != "=".code);
						break;
					}
					var name:String = null;
					if (hasSet) while (--k >= 0) {
						c = chunk.fastCodeAt(k);
						if (c.isSpace1()) continue;
						// perhaps `name/*:type*/ = val`?
						var suffix:String = null;
						if (c == "/".code && chunk.fastCodeAt(k - 1) == "*".code) {
							k -= 1;
							var suffixEnd = k;
							while (--k >= 0) {
								c = chunk.fastCodeAt(k);
								if (c == "*".code && chunk.fastCodeAt(k - 1) == "/".code) {
									if (chunk.fastCodeAt(k + 1) == ":".code) {
										suffix = chunk.substring(k + 1, suffixEnd);
									}
									k -= 2;
									while (k >= 0) {
										c = chunk.fastCodeAt(k);
										if (c.isSpace1()) k--; else break;
									}
									c = chunk.fastCodeAt(k);
									break;
								}
							}
						}
						// make sure that it's getting assigned into somewhere
						if (!c.isIdent1()) break;
						var nameEnd = k + 1;
						var nameStart = 0;
						while (--k >= 0) {
							c = chunk.fastCodeAt(k);
							if (c.isIdent1()) continue;
							nameStart = k + 1;
							break;
						}
						name = chunk.substring(nameStart, nameEnd);
						if (ntrx != null) {
							var mt = ntrx.exec(name);
							if (mt != null && mt[1] != null) name = mt[1];
						}
						if (suffix != null) name += suffix;
						// perhaps it's GMS1-style `if (argument_count > 1) v = argument[1]`?
						if (fromCode_skipIf(chunk, k) >= 0) isOpt = true;
						break;
					}
					if (name == null) name = "arg" + argi;
					if (isOpt) name = "?" + name;
					args[argi] = name;
				} else rest = true;
				mt = rx.exec(chunk);
			}
		}
		//
		while (q.pos < till) {
			var p = q.pos, n;
			if (q.peek() == "/".code && q.peek(1) == "*".code && q.peek(2) == ":".code) {
				q.pos += 2; q.skipComment(); n = -1;
			} else n = q.skipCommon_inline();
			if (n >= 0) {
				flush(p);
				start = q.pos;
			} else q.skip();
		}
		flush(q.pos);
		//
		post = ")";
		if (rest) post = "..." + post;
		if (hasRet) post += "➜";
		hasReturn = hasRet;
	}
	
	static var procHasReturn_rxHasArgArray:RegExp = new RegExp("\\bargument\\b\\s*\\[");
	/** A cheaper version of procCode that just figures out hasReturn and whether arguments might be optional */
	public function procHasReturn(gml:GmlCode, from:Int = 0, ?_till:Int, ?isAuto:Bool) {
		var start = from;
		var till:Int = _till != null ? _till : gml.length;
		var q = new GmlReader(gml);
		var chunk:GmlCode;
		var hasRetRx = fromCode_hasRet;
		var seekHasRet = true;
		var seekArg = isAuto && args.length > 0 && !rest;
		var hasArgRx = procHasReturn_rxHasArgArray;
		q.pos = from;
		while (q.pos < till) {
			var p = q.pos, n;
			var n = q.skipCommon_inline();
			if (n >= 0) {
				chunk = q.substring(start, p);
				if (seekHasRet && hasRetRx.test(chunk)) {
					seekHasRet = false;
					hasReturn = true;
					if (post == ")") post = ")➜";
					if (!seekArg) return;
				}
				if (seekArg && hasArgRx.test(chunk)) {
					seekArg = false;
					minArgsCache = 0;
					if (!seekHasRet) return;
				}
				start = q.pos;
			} else q.skip();
		}
		chunk = q.substring(start, q.pos);
		if (seekHasRet) {
			var hasRet = hasRetRx.test(chunk);
			if (hasRet) {
				if (post == ")") post = ")➜";
			} else {
				if (post == ")➜") post = ")";
			}
			hasReturn = hasRet;
		}
		if (seekArg && hasArgRx.test(chunk)) {
			minArgsCache = 0;
		}
	}
	
	static var autogen_argi = [for (i in 0 ... 16) new RegExp('\\bargument$i\\b')];
	static var autogen_argoi = [for (i in 0 ... 16) new RegExp('\\bargument\\s*\\[\\s*$i\\s*\\]')];
	static var autogen_argo = new RegExp("\\bargument\\b");
	
	public static function autoArgs(code:String) {
		var q = new GmlReader(code);
		var rxi = autogen_argi;
		var rxo = autogen_argo;
		var rxoi = autogen_argoi;
		var rxc = rxi;
		var trail = false;
		var argc = 0;
		var chunk:String;
		var start = 0;
		inline function flush(p:Int) {
			chunk = q.substring(start, p);
			if (!trail && rxo.test(chunk)) {
				trail = true;
				rxc = rxoi;
			}
			while (argc < 16) {
				if (rxc[argc].test(chunk)) argc += 1; else break;
			}
		}
		while (q.loop) {
			var p = q.pos;
			var n = q.skipCommon_inline();
			if (n >= 0) {
				flush(p);
				start = q.pos;
			} else q.skip();
		}
		flush(q.pos);
		if (argc == 0) return trail ? "..." : "";
		var out = "v0";
		for (i in 1 ... argc) out += ", v" + i;
		if (trail) out += ", ...";
		return out;
	}
}
