package gml.funcdoc;
import gml.GmlFuncDoc;
import js.lib.RegExp;
import parsers.GmlReader;
import tools.CharCode;
import tools.RegExpCache;
import tools.Aliases;
using tools.NativeString;

/**
 * Resolves argument names, whether they are optional, and whether a script/function returns anything.
 * This is more costly than ArgsRet.
 * @author YellowAfterlife
 */
class GmlFuncDocFromCode {
	static var rxArg:RegExp = new RegExp("\\bargument(?:"
		+ "(\\d+)" // argument0
		+ "|\\s*\\[\\s*(?:(\\d+)\\s*\\])?" // argument[0] | argument[???]
	+ ")", "g");
	static var rxHasVarArg = new RegExp("\\bargument_count\\b");
	static var rxHasReturn:RegExp = new RegExp("\\breturn\\b\\s*[^;]");
	private static function skipArgCountCmp(chunk:GmlCode, k:Int):Int {
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
	private static function skipOptArg(chunk:GmlCode, k:Int):Int {
		var c:CharCode;
		// `if (argument_count > 1)[ ]some = argument[1]`
		while (k >= 0) {
			c = chunk.fastCodeAt(k);
			if (c.isSpace1()) k--; else break;
		}
		// `if (argument_count > 1[)] some = argument[1]`
		if (chunk.fastCodeAt(k) != ")".code) return -1;
		k = skipArgCountCmp(chunk, k);
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
	
	public static function proc(doc:GmlFuncDoc, gml:String, from:Int = 0, ?_till:Int) {
		var rx = rxArg;
		doc.clear();
		var ntrx = GmlFuncDoc.nameTrimRegex.update(Project.current.properties.argNameRegex);
		//
		var hasRet = false;
		var hasRetRx = rxHasReturn;
		var hasVarArg = false;
		var hasVarArgRx = rxHasVarArg;
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
							var k1 = skipArgCountCmp(chunk, k);
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
						if (skipOptArg(chunk, k) >= 0) isOpt = true;
						break;
					}
					if (name == null) name = "arg" + argi;
					if (isOpt) {
						hasOpt = true;
						name = "?" + name;
					}
					doc.args[argi] = name;
				} else doc.rest = true;
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
		if (doc.rest) doc.args.push("...");
		if (hasRet) {
			if (doc.post == ")") doc.post = GmlFuncDoc.parRetArrow;
		} else {
			doc.post = ")";
		}
		doc.hasReturn = hasRet;
		if (!hasOpt && hasVarArg) @:privateAccess doc.minArgsCache = 0;
	}
}