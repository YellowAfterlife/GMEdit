package parsers;
import js.lib.RegExp;
import tools.Aliases;
import gml.GmlAPI;
import gml.Project;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtTemplateStrings {
	static function pre_format(fmt:String, args:Array<String>, spacing:Array<Bool>) {
		var out = "";
		var start = 0;
		var p = 0;
		var n = fmt.length;
		var index = 0;
		while (p < n) {
			var c = fmt.fastCodeAt(p++);
			if (c == "%".code) {
				out += fmt.substring(start, p - 1);
				var i = index++;
				var arg = args[i];
				if (spacing[i]) {
					out += "${" + pre(arg) + "}";
				} else if (arg == '"%"') {
					out += "%";
				} else if (rxWord.test(arg)) {
					out += "$" + arg;
				} else {
					out += "${" + pre(arg) + "}";
				}
				start = p;
			}
		}
		if (p > start) out += fmt.substring(start, p);
		return out;
	}
	private static var rxWord:RegExp = new RegExp("^\\w+$");
	public static function pre(code:GmlCode):GmlCode {
		if (!GmlAPI.forceTemplateStrings) return code;
		var tpls = Project.current.properties.templateStringScript;
		if (tpls == null || tpls == "") return code;
		var version = GmlAPI.version;
		var q = new GmlReader(code);
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		while (q.loop) {
			var startInner = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "@".code: q.skipStringAuto(c, version);
				case "#".code: if (startInner == 0 || q.get(startInner - 1) == "\n".code) {
					var ctx = q.readContextName(null);
				};
				case _ if (c.isIdent0()): {
					q.skipIdent1();
					do {
						if (q.substring(startInner, q.pos) != tpls) break;
						q.skipSpaces1_local();
						if (q.peek() == "(".code) q.skip(); else break;
						q.skipSpaces1_local();
						var isLiteral = (q.peek() == '@'.code);
						if (isLiteral) q.skip();
						if (q.peek() == '"'.code) q.skip(); else break;
						var fmt:String; {
							var fmtStart = q.pos;
							q.skipStringAuto('"'.code, version);
							fmt = q.substring(fmtStart, q.pos - 1);
						};
						q.skipSpaces1_local();
						var args:Array<String> = [];
						var spacing:Array<Bool> = [];
						if (q.peek() == ",".code) {
							q.skip();
							var hasSpace = (q.peek() == " ".code);
							if (hasSpace) q.skip();
							var argStart = q.pos;
							var depth = 0;
							inline function flushArg():Void {
								args.push(q.substring(argStart, q.pos - 1));
								spacing.push(hasSpace);
							}
							while (q.loop) {
								c = q.read();
								switch (c) {
									case "(".code, "[".code, "{".code: depth++;
									case ")".code, "]".code, "}".code: {
										if (--depth < 0) {
											flushArg();
											break;
										}
									};
									case ",".code: if (depth == 0) {
										flushArg();
										hasSpace = (q.peek() == " ".code);
										if (hasSpace) q.skip();
										argStart = q.pos;
									};
									case "/".code: switch (q.peek()) {
										case "/".code: q.skipLine();
										case "*".code: q.skip(); q.skipComment();
										default:
									};
									case '"'.code, "'".code, "@".code: q.skipStringAuto(c, version);
								}
							}
						} else if (q.peek() == ")".code) {
							q.skip();
						} else break;
						//
						flush(startInner);
						out += "`" + pre_format(fmt, args, spacing) + "`";
						start = q.pos;
					} while (false);
				};
				default:
			}
		}
		flush(q.pos);
		return out;
	}
	public static function post(code:GmlCode):GmlCode {
		if (!GmlAPI.forceTemplateStrings) return code;
		var tpls = Project.current.properties.templateStringScript;
		if (tpls == null || tpls == "") return code;
		var version = GmlAPI.version;
		var q = new GmlReader(code);
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "@".code: q.skipStringAuto(c, version);
				case "`".code: {
					flush(p);
					var curFmt = "";
					var curArgs = "";
					var curStart = q.pos;
					var curEnd = -1;
					while (q.loopLocal) {
						c = q.read();
						if (c == "`".code) {
							curEnd = q.pos - 1;
							break;
						}
						if (c == "%".code) {
							curFmt += q.substring(curStart, q.pos - 1) + "%";
							curArgs += ',"%"';
							curStart = q.pos;
							continue;
						}
						if (c != "$".code) continue;
						var c1 = q.peek();
						if (c1.isIdent0()) {
							curFmt += q.substring(curStart, q.pos - 1) + "%";
							var idStart = q.pos;
							q.skipIdent1();
							curArgs += ',' + q.substring(idStart, q.pos);
							curStart = q.pos;
							continue;
						}
						if (c1 != "{".code) continue;
						//{ sub-expr
						curFmt += q.substring(curStart, q.pos - 1) + "%";
						q.skip();
						var argStart = q.pos;
						var argEnd = -1;
						var argDepth = 0;
						while (q.loopLocal) {
							c = q.read();
							switch (c) {
								case "{".code: argDepth++;
								case "}".code: {
									if (--argDepth < 0) {
										argEnd = q.pos - 1;
										break;
									}
								};
								case "/".code: switch (q.peek()) {
									case "/".code: q.skipLine();
									case "*".code: q.skip(); q.skipComment();
									default:
								};
								case '"'.code, "'".code, "@".code, "`".code: {
									q.skipStringAuto(c, version);
								};
							}
						}
						if (argEnd < 0) argEnd = q.pos;
						var argVal = q.substring(argStart, argEnd);
						curArgs += ", " + post(argVal);
						curStart = q.pos;
						//}
					} // `` loop, can continue
					if (curEnd < 0) curEnd = q.pos;
					curFmt += q.substring(curStart, curEnd);
					out += tpls + '("' + curFmt + '"' + curArgs + ')';
					start = q.pos;
				};
				default:
			}
		}
		flush(q.pos);
		return out;
	}
}