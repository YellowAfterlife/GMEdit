package gml;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTools;
import js.lib.RegExp;
import parsers.GmlReader;
import tools.CharCode;
import tools.Aliases;
import tools.JsTools;
import tools.NativeArray;
import tools.RegExpCache;
using StringTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFuncDoc {
	
	public static inline var retArrow:String = "➜";
	public static inline function patchArrow(s:String):String {
		return StringTools.replace(s, "->", retArrow);
	}
	
	public var name:String;
	
	/** "func(" */
	public var pre:String;
	
	/** "): doc" */
	public var post:String;
	
	/** an array of argument names */
	public var args:Array<String>;
	
	public var argTypes:Array<GmlType> = null;
	
	public var hasReturn:Bool = null;
	
	/**
	 * Whether this is a 2.3 `function(...) constructor`
	 * (implications: should only be called via `new`, does not need to return)
	 */
	public var isConstructor:Bool = false;
	
	/** If this is a 2.3 constructor and it inherits from another, this is the name of that */
	public var parentName:String = null;
	
	/** Type of `self` set via `/// @self` */
	public var selfType:GmlType = null;
	
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
	
	/** Return type based on `->type` or `@return` for post-string */
	public var returnType(get, never):GmlType;
	private function get_returnType():GmlType {
		if (post == __returnType_cache_post) return __returnType_cache_type;
		var mt = __returnType_rx.exec(post);
		var str = JsTools.nca(mt, mt[1]);
		var type:GmlType;
		if (str != null) {
			if (templateNames != null) {
				str = GmlTypeTools.patchTemplateNames(str, templateNames);
			}
			type = GmlTypeDef.parse(str);
		} else type = null;
		__returnType_cache_post = post;
		__returnType_cache_type = type;
		return type;
	}
	var __returnType_cache_post:String;
	var __returnType_cache_type:GmlType;
	static var __returnType_rx:RegExp = new RegExp('^\\)$retArrow(\\S+)');
	
	public var templateNames:Array<String> = null;
	
	public var maxArgs(get, never):Int;
	private function get_maxArgs():Int {
		return rest ? 0x7fffffff : args.length;
	}
	
	/** whether to show "..." in the end of argument list */
	public var rest:Bool;
	
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
		minArgsCache = null;
	}
	
	public function getAcText() {
		return pre + args.join(", ") + post;
	}
	
	public static function create(name:String, ?args:Array<String>, ?rest:Bool):GmlFuncDoc {
		if (args == null) {
			args = [];
			if (rest == null) rest = false;
		} else if (rest == null) {
			rest = false;
			for (arg in args) {
				if (arg.contains("...")) rest = true;
			}
		}
		return new GmlFuncDoc(name, name + "(", ")", args, rest);
	}
	
	public static function createRest(name:String):GmlFuncDoc {
		return new GmlFuncDoc(name, name + "(", ")", ["..."], true);
	}
	
	/** ("func(a, b)") -> { pre:"func(", args:["a","b"], post:")" } */
	public static function parse(s:String, ?out:GmlFuncDoc):GmlFuncDoc {
		s = patchArrow(s);
		var p0 = s.indexOf("(");
		var p1 = s.indexOf(")", p0);
		var name:String, pre:String, post:String, args:Array<String>, rest:Bool;
		var argTypes:Array<GmlType> = null;
		var templateNames:Array<String> = null;
		if (p0 >= 0 && p1 >= 0) {
			name = s.substring(0, p0); {
				var mt = parse_rxTemplate.exec(name);
				if (mt != null) {
					name = mt[1];
					templateNames = mt[2].splitRx(JsTools.rx(~/,\s*/g));
				}
			}
			var sw = s.substring(p0 + 1, p1).trimBoth();
			pre = s.substring(0, p0 + 1);
			post = s.substring(p1);
			if (sw != "") {
				args = sw.splitRx(JsTools.rx(~/,\s*/g));
				var rxt = JsTools.rx(~/:([^=]+)/);
				for (i => a in args) {
					var mt = rxt.exec(a);
					if (mt != null) {
						if (argTypes == null) argTypes = NativeArray.create(args.length);
						var typeStr = mt[1];
						if (templateNames != null) {
							typeStr = GmlTypeTools.patchTemplateNames(typeStr, templateNames);
						}
						argTypes[i] = GmlTypeDef.parse(typeStr);
					}
				}
			} else args = [];
			rest = sw.contains("...");
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
		} else {
			out = new GmlFuncDoc(name, pre, post, args, rest);
		}
		out.argTypes = argTypes;
		out.templateNames = templateNames;
		return out;
	}
	static var parse_rxTemplate = new RegExp("^(.*)" + "<(.+?)>");
	
	static var fromCode_rx:RegExp = new RegExp("\\bargument(?:"
		+ "(\\d+)" // argument0
		+ "|\\s*\\[\\s*(?:(\\d+)\\s*\\])?" // argument[0] | argument[???]
	+ ")", "g");
	static var fromCode_hasVarArg = new RegExp("\\bargument_count\\b");
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
	
	public static function splitOnSubFunctions(gml:String):Array<String> {
		if (!GmlAPI.stdKind.exists("function")) return [gml];
		var arr:Array<String> = [];
		var start = 0;
		var q = new GmlReader(gml);
		while (q.loop) {
			var n = q.skipCommon_inline();
			if (n >= 0) continue;
			//
			var p = q.pos;
			var c = q.read();
			if (!c.isIdent0()) continue;
			q.skipIdent1();
			var id = q.substring(p, q.pos);
			if (id != "function") continue;
			//
			while (q.loop && q.peek() != "{".code) q.skip();
			var depth = 1;
			while (q.loop) {
				c = q.read();
				switch (c) {
					case "{".code: depth++;
					case "}".code: if (--depth <= 0) break;
					default: q.skipCommon_inline();
				}
			}
			//
			arr.push(gml.substring(start, p));
			start = q.pos;
		}
		arr.push(gml.substring(start));
		return arr;
	}
	
	static var nameTrimRegex = new RegExpCache();
	
	public function trimArgs():Void {
		var ntrx = nameTrimRegex.update(Project.current.properties.argNameRegex);
		if (ntrx == null) return;
		for (i in 0 ... args.length) {
			var mt = ntrx.exec(args[i]);
			if (mt != null && mt[1] != null) args[i] = mt[1];
		}
	}
	
	public function fromCode(gml:String, from:Int = 0, ?_till:Int) {
		var rx = fromCode_rx;
		clear();
		var ntrx = nameTrimRegex.update(Project.current.properties.argNameRegex);
		//
		var hasRet = false;
		var hasRetRx = fromCode_hasRet;
		var hasVarArg = false;
		var hasVarArgRx = fromCode_hasVarArg;
		var hasOpt = false;
		var q:GmlReader = null, start:Int = 0;
		function flush(p:Int):Void {
			var chunk = q.substring(start, p);
			rx.lastIndex = 0;
			var mt = rx.exec(chunk);
			var c:CharCode;
			if (!hasRet && hasRetRx.test(chunk)) hasRet = true;
			if (!hasVarArg && hasVarArgRx.test(chunk)) hasVarArg = true;
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
					if (isOpt) {
						hasOpt = true;
						name = "?" + name;
					}
					args[argi] = name;
				} else rest = true;
				mt = rx.exec(chunk);
			}
		}
		//
		var sections = splitOnSubFunctions(gml.substring(from, _till));
		for (section in sections) {
			q = new GmlReader(section);
			start = 0;
			while (q.loop) {
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
		}
		//
		post = ")";
		if (rest) post = "..." + post;
		if (hasRet) post += retArrow;
		hasReturn = hasRet;
		if (!hasOpt && hasVarArg) minArgsCache = 0;
	}
	
	static var procHasReturn_rxHasArgArray:RegExp = new RegExp("\\bargument\\b\\s*\\[");
	/**
	 * A cheaper version of procCode that just figures out hasReturn and whether arguments might be optional.
	 * 
	 */
	public function procHasReturn(gml:GmlCode, from:Int = 0, ?_till:Int, ?isAuto:Bool, ?autoArgs:Array<String>) {
		var start = from;
		var till:Int = _till != null ? _till : gml.length;
		var q = new GmlReader(gml);
		var chunk:GmlCode;
		var hasRetRx = fromCode_hasRet;
		var seekHasRet = true;
		var seekArg = isAuto && args.length > 0 && !rest;
		var hasArgRx = procHasReturn_rxHasArgArray;
		//
		var autoRxs:Array<RegExp> = null;
		if (autoArgs != null) try {
			autoRxs = [];
			for (arg in autoArgs) autoRxs.push(new RegExp('\\b$arg\\s*[!=]=\\s*undefined'));
		} catch (_:Dynamic) autoRxs = null;
		inline function checkAutoRxs() {
			if (autoRxs == null) return;
			var m = minArgsCache;
			if (m == 0) return;
			var n = m != null ? m : autoRxs.length;
			var i = -1; while (++i < n) {
				if (autoRxs[i].test(chunk)) {
					minArgsCache = i;
					break;
				}
			}
		}
		//
		q.pos = from;
		while (q.pos < till) {
			var p = q.pos, n;
			var n = q.skipCommon_inline();
			if (n >= 0) {
				chunk = q.substring(start, p);
				if (seekHasRet && hasRetRx.test(chunk)) {
					seekHasRet = false;
					hasReturn = true;
					if (post == ")") post = ")" + retArrow;
					if (!seekArg) return;
				}
				if (seekArg && hasArgRx.test(chunk)) {
					// mimicking 2.3 IDE behaviour where having
					// argument[] access makes all arguments optional.
					seekArg = false;
					minArgsCache = 0;
					rest = true;
					if (!seekHasRet) return;
				}
				checkAutoRxs();
				start = q.pos;
			} else q.skip();
		}
		chunk = q.substring(start, q.pos);
		// final:
		if (seekHasRet) {
			var hasRet = hasRetRx.test(chunk);
			if (hasRet) {
				if (post == ")") post = ")" + retArrow;
			} else {
				if (post == ")" + retArrow) post = ")";
			}
			hasReturn = hasRet;
		}
		if (seekArg && hasArgRx.test(chunk)) {
			minArgsCache = 0;
			rest = true;
		}
		checkAutoRxs();
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
