package parsers;
import haxe.Json;
import haxe.ds.Vector;
import tools.Aliases;
import tools.Dictionary;
using tools.NativeString;
import ui.Preferences;
import gml.GmlAPI;
import ace.extern.AceAutoCompleteItem;

/**
 * This handles
 * #mfunc some(a, b) [b,a ,b]
 * return some(1, 2)
 * <->
 * //!#mfunc some a b [1,0,1]
 * #macro some_mf0  [
 * #macro some_mf1 ,
 * #macro some_mf2  ,
 * #macro some_mf3 ]
 * return some_mf0 2 some_mf1 1 some_mf2 2 some_mf3
 * 
 * Note: index literal is split index -> arg index
 * @author YellowAfterlife
 */
class GmlExtMFunc {
	public var name:String;
	public var args:Array<String>;
	public var order:Array<Int>;
	public var comp:AceAutoCompleteItem;
	public function new(name:String, json:GmlExtMFuncData) {
		this.name = name;
		args = json.args;
		order = json.order;
		comp = new AceAutoCompleteItem(name, "mfunc", name + "(" + args.join(",") + ")");
	}
	
	public static var errorText:String = null;
	public static function pre(code:GmlCode):GmlCode {
		if (!Preferences.current.mfuncMagic) return code;
		var q = new GmlReader(code);
		var v = q.version;
		//
		inline function is_mf0():Bool {
			return q.peek( -4) == "_".code
				&& q.peek( -3) == "m".code
				&& q.peek( -2) == "f".code
				&& q.peek( -1) == "0".code;
		}
		function proc(mf:GmlExtMFunc, pre:String):String {
			var orig_pos = q.pos;
			var c = q.peek();
			var beforeParOpen = "";
			if (c.isSpace0()) {
				q.skip();
			} else if (c == "/".code && q.peek(1) == "*".code) {
				q.pos = q.source.indexOf("*/", q.pos);
				if (q.pos < 0) {
					q.pos = orig_pos;
					return pre + "0";
				} else {
					beforeParOpen = q.substring(orig_pos + 2, q.pos);
					q.pos += 2;
				}
			}
			var start = q.pos;
			var ind = 1;
			var next:String = pre + ind;
			var args:Vector<String> = new Vector(mf.args.length);
			var order = mf.order;
			var out = "";
			while (q.loop) {
				var p = q.pos;
				c = q.read();
				switch (c) {
					case "/".code: switch (q.peek()) {
						case "/".code: q.skipLine();
						case "*".code: q.skip(); q.skipComment();
					}
					case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, v);
					case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
						var ctx = q.readContextName(null);
					};
					case _ if (c.isIdent0()): {
						q.skipIdent1();
						if (is_mf0()) {
							var mf = GmlAPI.gmlMFuncs[q.substring(p, q.pos - 4)];
							if (mf != null) {
								out += q.substring(start, p)
									+ proc(mf, q.substring(p, q.pos - 1));
								start = q.pos;
							}
						}
						else if (q.substring(p, q.pos) == next) {
							// trim space before argument:
							c = q.get(p - 1);
							if (c.isSpace0()) p--;
							//
							var arg = out + q.substring(start, p);
							out = "";
							var ai = order[ind - 1];
							//Main.console.log(orig_pos, ai, ind, '`$arg`');
							var oldArg = args[ai];
							if (oldArg != null) {
								if (oldArg != arg) {
									Main.console.error('mfunc violation: argument[$ai]'
										+ ' is already set to `$oldArg` but new value is `$arg`');
									break;
								}
							} else args[ai] = arg;
							//
							if (++ind > order.length) {
								return mf.name + beforeParOpen + "(" + args.join(",") + ")";
							} else {
								c = q.peek();
								if (c.isSpace0()) q.skip();
								start = q.pos;
								next = pre + ind;
							}
						}
					};
					default:
				}
			}
			Main.console.error("Unclosed mfunc " + mf.name);
			q.pos = orig_pos;
			return pre + "0";
		}
		//
		var start = 0;
		var out = "";
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: {
						q.skipLine();
						if (q.get(p + 2) == "!".code
						&& q.get(p + 3) == "#".code
						&& q.substr(p + 4, 6) == "mfunc ") {
							flush(p);
							var line = q.substring(p + 10, q.pos);
							var nameEnd = line.indexOf(" ");
							var name = line.substring(0, nameEnd);
							var json:{args:Array<String>, order:Array<Int>}
								= Json.parse(line.substring(nameEnd + 1));
							var args:Array<String> = json.args;
							var order:Array<Int> = json.order;
							var ok = false;
							//
							var mf = "#mfunc " + name + "(" + args.join(",") + ")";
							var i = 0;
							var n = order.length;
							var pre = "#macro " + name + "_mf";
							while (i <= n) {
								q.skipSpaces1();
								// ¦#macro some_mf0 [
								var cpre = pre + i + " ";
								if (q.substring(q.pos, q.pos + cpre.length) != cpre) break;
								q.pos += cpre.length;
								// #macro some_mf0 ¦[
								var cvp = q.pos;
								q.skipLine();
								while (q.peek( -1) == "\\".code && q.loop) {
									q.skipLineEnd();
									q.skipLine();
								}
								var cval = q.substring(cvp, q.pos); // `[`
								if (NativeString.endsWith(cval, "//")) {
									cval = cval.substring(0, cval.length - 2);
								}
								mf += cval;
								if (i < n) mf += args[order[i]].trimBoth();
								i++;
							}
							//
							if (i > n) {
								out += mf;
								start = q.pos;
							}
						}
					};
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, v);
				case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
					var ctx = q.readContextName(null);
				};
				case _ if (c.isIdent0()): {
					q.skipIdent1();
					if (is_mf0()) {
						var mf = GmlAPI.gmlMFuncs[q.substring(p, q.pos - 4)];
						if (mf != null) {
							out += q.substring(start, p);
							out += proc(mf, q.substring(p, q.pos - 1));
							start = q.pos;
						}
					}
				};
				default:
			}
		}
		if (start == 0) return code;
		flush(q.pos);
		return out;
	}
	
	
	public static function post(code:GmlCode):GmlCode {
		if (!Preferences.current.mfuncMagic) return code;
		var version = GmlAPI.version;
		var q = new GmlReader(code);
		inline function error(s:String) {
			errorText = s;
			return null;
		}
		var nextMap = new Dictionary<GmlExtMFunc>();
		//
		function proc(mf:GmlExtMFunc):String {
			var name = mf.name;
			//
			var start = q.pos;
			q.skipSpaces0();
			var spacesBeforeParOpen = q.substring(start, q.pos);
			//
			if (q.read() != "(".code) return error("Expected a `(` after " + name);
			start = q.pos;
			var depth = 1;
			var args:Array<String> = [];
			var out = "";
			inline function flushArg(till:Int):Void {
				args.push(out + q.substring(start, till));
				out = "";
			}
			while (q.loop) {
				var p = q.pos;
				var c = q.read();
				switch (c) {
					case "(".code: depth++;
					case ")".code: if (--depth <= 0) {
						flushArg(p);
						if (args.length != mf.args.length) return error('Argument count mismatch for '
							+ name + ' - expected ' + mf.args.length + ', got ' + args.length);
						var pre = name + "_mf";
						var out = pre + "0";
						var order = mf.order;
						var nosep = spacesBeforeParOpen != "";
						if (nosep) out += "/*" + spacesBeforeParOpen + "*/";
						for (i in 0 ... order.length) {
							if (nosep) nosep = false; else out += " ";
							out += args[order[i]] + " " + pre + (i + 1);
						}
						// auto-fix `some(...)exit` -> `...some_mfXexit`
						c = q.peek(); if (c.isIdent1()) out += " ";
						return out;
					};
					case ",".code: if (depth == 1) {
						flushArg(p);
						start = q.pos;
					};
					case _ if (c.isIdent0()): {
						q.skipIdent1();
						var name = q.substring(p, q.pos);
						var mf1 = nextMap[name];
						if (mf1 == null) mf1 = GmlAPI.gmlMFuncs[name];
						if (mf1 != null) {
							out += q.substring(start, p);
							var call = proc(mf1);
							if (call == null) return null;
							out += call;
							start = q.pos;
						}
					};
				}
			}
			return error("Unclosed() after " + name);
		}
		//
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
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				case "#".code: {
					if (q.substr(p + 1, 5) == "mfunc" && !q.peek(p + 6).isIdent1()) {
						flush(p);
						q.skip(6);
						q.skipSpaces0();
						var nameStart = q.pos;
						q.skipIdent();
						//
						var name = q.substring(nameStart, q.pos);
						if (name == "") return error("No name provided");
						q.skipSpaces0();
						//
						if (q.read() != "(".code) return error("Expected a `(` after " + name);
						var argFulls:Array<String> = [];
						var argMap:Dictionary<Int> = new Dictionary();
						var argsOK = false;
						while (q.loop) {
							var argStart = q.pos;
							q.skipSpaces0();
							var argNameStart = q.pos;
							q.skipIdent();
							var argName = q.substring(argNameStart, q.pos);
							if (argName == "") return error("Expected an argument name for argument["
								+ argFulls.length + '] in $name');
							q.skipSpaces0();
							var argFull = q.substring(argStart, q.pos);
							if (argMap.exists(argName)) {
								return error('Argument redefinition for `$argName` in `$name`');
							} else argMap.set(argName, argFulls.length);
							argFulls.push(argFull);
							//
							switch (q.read()) {
								case ",".code: {}; // OK!
								case ")".code: argsOK = true; break;
								default: return error('Unexpected character `'
									 + String.fromCharCode(q.peek( -1))
									 + '` in arguments for $name');
							}
						}
						if (!argsOK) return error('Expected a `(` after $name\'s arguments');
						// the time has come to read the macro value
						var argStart = q.pos;
						var mfArgs = "";
						var order:Array<Int> = [];
						inline function argFlush():Void {
							var arg = q.substring(argStart, p);
							if (NativeString.trimRight(arg) == "") arg += "//";
							mfArgs += '\n#macro ${name}_mf' + order.length + ' $arg';
						}
						while (q.loop) {
							p = q.pos;
							c = q.read();
							switch (c) {
								case "/".code: switch (q.peek()) {
									case "/".code, "*".code: return error(
										'Comments are not supported in macro-functions, for $name');
									default:
								};
								case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
								case "\r".code, "\n".code: {
									switch (q.get(p - 1)) {
										case "\r".code: {}; // it's \r\n
										case "\\".code: {}; // escaped
										default: q.pos--; break; // -> val¦\r\n
									}
								};
								default: {
									if (c.isIdent0()) {
										q.skipIdent1();
										var i = argMap[q.substring(p, q.pos)];
										if (i != null) {
											argFlush();
											order.push(i);
											argStart = q.pos;
										}
									}
								};
							}
						}
						argFlush();
						//
						var json:GmlExtMFuncData = {
							args: argFulls,
							order: order,
						};
						var mf = new GmlExtMFunc(name, json);
						nextMap.set(name, mf);
						out += '//!#mfunc $name ' + Json.stringify(json) + mfArgs;
						start = q.pos;
					} else if (p == 0 || q.get(p - 1) == "\n".code) {
						var ctx = q.readContextName(null);
					}
				};
				case _ if (c.isIdent0()): {
					q.skipIdent1();
					var name = q.substring(p, q.pos);
					var mf = nextMap[name];
					if (mf == null) mf = GmlAPI.gmlMFuncs[name];
					if (mf != null) {
						flush(p);
						var call = proc(mf);
						if (call == null) return null;
						out += call;
						start = q.pos;
					}
				};
				default:
			}
		}
		flush(q.pos);
		if (false) {
			Main.console.log(out);
			return null;
		} else return out;
	}
}
typedef GmlExtMFuncData = {
	/** ["one", " two"] (incl. spacing around) */
	var args:Array<String>;
	
	/** [1,0,1] for `#mfunc some(a,b) [b,a,b]`*/
	var order:Array<Int>;
}
