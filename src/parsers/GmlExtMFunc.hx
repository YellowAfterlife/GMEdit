package parsers;
import haxe.Json;
import haxe.ds.Vector;
import tools.Aliases;
import tools.Dictionary;
import editors.EditCode;
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
	public var order:Array<GmlExtMFuncOrder>;
	public var comp:AceAutoCompleteItem;
	public var hasRest:Bool;
	public function new(name:String, json:GmlExtMFuncData) {
		this.name = name;
		args = json.args;
		order = json.order;
		comp = new AceAutoCompleteItem(name, "macro", name + "(" + args.join(",") + ")");
		hasRest = args.length > 0 && args[args.length - 1].trimBoth() == "...";
	}
	
	public static var magicRegex:String = "";
	public static var magicMap:Dictionary<GmlExtMFuncMagic> = __magicMap_init();
	static function __magicMap_init() {
		var map = new Dictionary<GmlExtMFuncMagic>();
		var rx:String = "(@@)(__(?:";
		var rxSep = false;
		function add(name:String, fn:GmlExtMFuncMagic):Void {
			if (rxSep) rx += "|"; else rxSep = true;
			var full = '__${name}__';
			rx += name + "__";
			map.set("__" + name + "__", fn);
		}
		add("FILE", (e:EditCode, _) -> Json.stringify(e.file.name));
		add("HERE", (e:EditCode, _) -> e.file.name);
		add("DATE", (e:EditCode, _) -> Json.stringify(DateTools.format(Date.now(), "%F")));
		add("TIME", (e:EditCode, _) -> Json.stringify(DateTools.format(Date.now(), "%T")));
		function getLine(q:GmlReader):Int {
			var n = 0;
			var i = q.pos;
			while (i >= 0) {
				n++;
				i = q.source.lastIndexOf("\n", i - 1);
			}
			return n;
		}
		add("LINE", (e:EditCode, q) -> "" + getLine(q));
		add("LINE_STR", (e:EditCode, q) -> '"' + getLine(q) + '"');
		//
		map["argument"] = (e, q) -> "argument";
		map["argument_count"] = (e, q) -> "argument_count";
		function makeArgFun(i:Int) return (e, q) -> "argument" + i;
		for (i in 0 ... 16) map["argument"+i] = makeArgFun(i);
		//
		rx += "))";
		magicRegex = rx;
		return map;
	}
	
	public static var errorText:String = null;
	public static function pre(editor:EditCode, code:GmlCode):GmlCode {
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
			if (mf.order.length == 0) return mf.name + "()";
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
			inline function error(s:String) {
				Main.console.error('[mfunc] for ${mf.name}: ' + s);
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
					case "#".code: {
						if (p == 0 || q.get(p - 1) == "\n".code) {
							var ctx = q.readContextName(null);
						};
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
							var arg = out + q.substring(start, p); out = "";
							//
							var ai:Int, s:String, s2:String, pad:String, trim:String;
							var ord = order[ind - 1];
							if (ord.isPlain()) {
								ai = ord.asPlain();
							} else switch (ord.kind) {
								case Plain: ai = ord.arg;
								case Magic: ai = -1;
								case Quoted: {
									ai = ord.arg;
									arg = try Json.parse(arg) catch (x:Dynamic) {
										error('argument[$ai] `$arg` is invalid JSON.');
										break;
									};
								};
								case Pre, Post, PrePost: {
									ai = ord.arg;
									// Pre, PrePost
									s = ord.asArray()[2];
									if (ord.kind != Post) {
										trim = arg.trimLeft();
										pad = arg.substring(0, arg.length - trim.length);
										if (trim.startsWith(s)) {
											arg = pad + trim.substring(s.length);
										} else {
											error('argument[$ai] `$arg` is supposed '
												+ 'to start with `$s` but does not.');
											break;
										}
									}
									// Post, PrePost
									if (ord.kind == PrePost) s = ord.asArray()[3];
									if (ord.kind != Pre) {
										trim = arg.trimRight();
										pad = arg.substring(trim.length);
										if (trim.endsWith(s)) {
											arg = trim.substring(0, trim.length - s.length) + pad;
										} else {
											error('argument[$ai] `$arg` is supposed '
												+ 'to end with `$s` but does not.');
											break;
										}
									}
								};
							}
							if (ai >= 0) {
								var oldArg = args[ai];
								if (oldArg != null) {
									if (oldArg != arg) {
										error('argument[$ai]'
											+ ' is already set to `$oldArg` but new value is `$arg`');
										break;
									}
								} else args[ai] = arg;
							}
							//
							if (++ind > order.length) {
								ai = args.length;
								while (--ai >= 0) if (args[ai] == null) args[ai] = "undefined";
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
							var json:GmlExtMFuncData
								= Json.parse(line.substring(nameEnd + 1));	
							var args:Array<String> = json.args;
							var order = json.order;
							var ok = false;
							//
							var mf = "#mfunc " + name + "(" + args.join(",") + ")";
							if (json.token != null) mf += " as " + Json.stringify(json.token);
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
								if (i < n) {
									var ord = order[i];
									var ai:Int;
									if (ord == null) {
										ai = -1;
									} else if (ord.isPlain()) {
										ai = ord.asPlain();
									} else switch (ord.kind) {
										case Plain: ai = ord.arg;
										case Quoted: ai = ord.arg; mf += "@@";
										case Pre: mf += ord.asArray()[2] + "##"; ai = ord.arg;
										case Post: {
											ai = -1;
											mf += args[ord.arg].trimBoth() + "##" + ord.asArray()[2];
										};
										case PrePost: {
											ai = -1;
											mf += ord.asArray()[2] + "##" +
												args[ord.arg].trimBoth() + "##" + ord.asArray()[3];
										};
										case Magic: mf += "@@" + ord.asArray()[1]; ai = -1;
									}
									if (ai >= 0) {
										mf += args[ai].trimBoth();
									}
								}
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
				case "#".code: {
					if (q.peek() == "m".code &&
						q.peek(1) == "a".code &&
						q.peek(2) == "c".code &&
						q.peek(3) == "r".code &&
						q.peek(4) == "o".code &&
						q.peek(5).isSpace1_ni()
					) {
						q.skip(5);
						q.skipSpaces1();
						q.skipIdent();
						q.skipSpaces1();
						if (q.peek() == ":".code) {
							q.skip();
							q.skipSpaces1();
							q.skipIdent();
						}
					}
					else if (p == 0 || q.get(p - 1) == "\n".code) {
						var ctx = q.readContextName(null);
					};
				}
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
	
	
	public static function post(editor:EditCode, code:GmlCode):GmlCode {
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
			var orig_pos = q.pos;
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
					case "(".code, "[".code, "{".code: depth++;
					case ")".code, "]".code, "}".code: if (--depth <= 0) {
						flushArg(p);
						var mfl = mf.args.length;
						if (mfl == 0 && args.length == 1 && args[0].trimRight() == "") {
							args.pop();
						}
						if (mf.hasRest) {
							if (args.length < mfl) return error(
								'$name requires at least ${mf.args.length} arguments'
								+ ', ${args.length} provided.');
							if (args.length > mf.args.length) {
								var i = mfl - 1;
								var rest = args[i];
								while (++i < args.length) rest += "," + args[i];
								args.splice(mfl, args.length - mfl);
								args[mfl - 1] = rest;
							}
						} else {
							if (args.length != mfl) return error(
								'$name requires ${mf.args.length} arguments'
								+ ', ${args.length} provided.');
						}
						var pre = name + "_mf";
						var out = pre + "0";
						var order = mf.order;
						var nosep = spacesBeforeParOpen != "";
						if (nosep) out += "/*" + spacesBeforeParOpen + "*/";
						for (i in 0 ... order.length) {
							if (nosep) nosep = false; else out += " ";
							var ord = order[i];
							if (ord.isPlain()) {
								out += args[ord.asPlain()];
							} else switch (ord.kind) {
								case Plain: {};
								case Quoted: out += Json.stringify(args[ord.arg]);
								case Magic: {
									var _q_pos = q.pos;
									q.pos = orig_pos;
									out += magicMap[ord.asArray()[1]](editor, q);
									q.pos = _q_pos;
								};
								case Pre: out += args[ord.arg].insertAtPadLeft(ord.pstr(0));
								case Post: out += args[ord.arg].insertAtPadRight(ord.pstr(0));
								case PrePost: out += args[ord.arg].insertAtPadBoth(
									ord.pstr(0), ord.pstr(1));
							}
							out += " " + pre + (i + 1);
						}
						// auto-fix `some(...)exit` -> `...some_mfXexit`
						c = q.peek(); if (c.isIdent1()) out += " ";
						return out;
					};
					case "/".code: switch (q.peek()) {
						case "/".code: q.skipLine();
						case "*".code: q.skip(); q.skipComment();
						default:
					};
					case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
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
			inline function checkConcat():Bool {
				return q.peek() == "#".code && q.peek(1) == "#".code && q.peek(2).isIdent0_ni();
			}
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				case "#".code if (q.substr(p + 1, 5) == "mfunc" && !q.get(p + 6).isIdent1()): {
					flush(p);
					q.skip(6);
					q.skipSpaces0();
					var nameStart = q.pos;
					q.skipIdent();
					//
					var name = q.substring(nameStart, q.pos);
					if (name == "") return error("No name provided");
					q.skipSpaces0();
					
					// read the signature:
					if (q.read() != "(".code) return error("Expected a `(` after " + name);
					var argFulls:Array<String> = [];
					var argMap:Dictionary<Int> = new Dictionary();
					var argsOK = false;
					var seenRest = false;
					q.skipSpaces0();
					if (q.peek() == ")".code) { // it's just #mfunc name()
						q.skip();
						argsOK = true;
					}
					else while (q.loop) {
						var argStart = q.pos;
						q.skipSpaces0();
						var argNameStart = q.pos;
						if (seenRest) return error('Can\'t have arguments after `...`'
							+ ' argument in $name');
						if (q.peek() == ".".code && q.peek(1) == ".".code && q.peek(2) == ".".code) {
							q.skip(3); // it's a ...
							seenRest = true;
						} else q.skipIdent();
						var argName = q.substring(argNameStart, q.pos);
						if (argName == "") return error("Expected an argument name for argument["
							+ argFulls.length + '] in $name');
						q.skipSpaces0();
						//
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
					if (!argsOK) return error('Expected a `)` after $name\'s arguments');
					
					//
					var tokenType:String = null;
					do {
						var ttp = q.pos;
						var ttl = q.length;
						var ttc:tools.CharCode;
						while (ttp < ttl) {
							ttc = q.get(ttp);
							if (ttc.isSpace0()) ttp++; else break;
						}
						//
						if (q.get(ttp++) != "a".code) break;
						if (q.get(ttp++) != "s".code) break;
						if (q.get(ttp).isIdent1_ni()) break; // asz
						//
						while (ttp < ttl) {
							ttc = q.get(ttp);
							if (ttc.isSpace0()) ttp++; else break;
						}
						//
						if (q.get(ttp++) != '"'.code) break;
						var ttStart = ttp;
						var ttEnd = ttStart;
						while (ttp < ttl) {
							ttc = q.get(ttp++);
							switch (ttc) {
								case '"'.code: ttEnd = ttp - 1; break;
								case '\r'.code, '\n'.code: {
									return error('Unclosed token type for #mfunc $name');
								};
							}
						}
						if (ttEnd == ttStart) return error('Unclosed token type for #mfunc $name');
						//
						tokenType = q.substring(ttStart, ttEnd);
						q.pos = ttp;
					} while (false);
					
					// the time has come to read the macro value
					var argStart = q.pos;
					var mfArgs = "";
					var order:Array<GmlExtMFuncOrder> = [];
					inline function argFlush(i:Int = 0):Void {
						var arg = q.substring(argStart, p);
						if (NativeString.trimRight(arg) == "") arg += "//";
						mfArgs += '\n#macro ${name}_mf' + (i + order.length) + ' $arg';
					}
					while (q.loop) {
						p = q.pos;
						c = q.read();
						var s1:String, s2:String, s3:String;
						switch (c) {
							case "/".code: switch (q.peek()) {
								case "/".code, "*".code: return error(
									'Comments are not supported in macro-functions, for $name');
								default:
							};
							case "@".code if (q.peek() == "@".code && q.peek(1).isIdent0_ni()): {
								argFlush();
								q.skip();
								p = q.pos;
								q.skipIdent1();
								s1 = q.substring(p, q.pos);
								if (checkConcat()) return error(
									'Can\'t concat to a literal (@@$s1## in $name)'
								);
								var i = argMap[s1];
								if (i != null) {
									order.push(GmlExtMFuncOrder.Quoted(i));
								}
								else if (magicMap.exists(s1)) {
									order.push(GmlExtMFuncOrder.Magic(s1));
								}
								else return error('Unknown variable/global for literal ' +
									'($s1 in $name)');
								argStart = q.pos;
							};
							case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
							case "\r".code, "\n".code: {
								switch (q.get(p - 1)) {
									case "\r".code: {}; // it's \r\n
									case "\\".code: {}; // escaped
									default: q.pos--; break; // -> val¦\r\n
								}
							};
							case ".".code if (q.peek() == ".".code && q.peek(1) == ".".code): {
								q.skip(2);
								argFlush();
								var i = argMap["..."];
								if (i != null) {
									order.push(GmlExtMFuncOrder.Plain(i));
								} else return error("Using a `...` argument that is not defined.");
								argStart = q.pos;
							};
							case _ if (c.isIdent0()): {
								q.skipIdent1();
								s1 = q.substring(p, q.pos);
								var i = argMap[s1];
								if (i != null) {
									argFlush();
									if (checkConcat()) { // var##post
										q.skip(2);
										p = q.pos;
										q.skipIdent1();
										s2 = q.substring(p, q.pos);
										if (argMap.exists(s2)) return error('Argument concatenation'+
											' ($s1##$s2, in $name) is not supported.'
										);
										if (checkConcat()) return error(
											'Cannot concat more than two identifiers'+
											' ($s1##$s2##, in #name)'
										);
										order.push(GmlExtMFuncOrder.Post(i, s2));
									} else {
										order.push(GmlExtMFuncOrder.Plain(i));
									}
									argStart = q.pos;
								}
								else if (checkConcat()) { // pre##var
									argFlush();
									q.skip(2);
									p = q.pos;
									q.skipIdent1();
									s2 = q.substring(p, q.pos);
									i = argMap[s2];
									if (i == null) return error('One of the concat arguments'+
										' should be a variable ($s1##$s2, in $name).'
									);
									if (checkConcat()) { // pre##var##post
										q.skip(2);
										p = q.pos;
										q.skipIdent1();
										s3 = q.substring(p, q.pos);
										if (argMap.exists(s3)) return error(
											'Can only concat prefix+var+suffix'+
											' ($s1##$s2##$s3, in $name)'
										);
										if (checkConcat()) return error(
											'Cannot concat more than two identifiers'+
											' ($s1##$s2##, in $name)'
										);
										order.push(GmlExtMFuncOrder.PrePost(i, s1, s3));
									} else order.push(GmlExtMFuncOrder.Pre(i, s1));
									argStart = q.pos;
								}
							}
						}
					}
					argFlush();
					//
					var json:GmlExtMFuncData = {
						args: argFulls,
						order: order,
					};
					if (tokenType != null) json.token = tokenType;
					var mf = new GmlExtMFunc(name, json);
					nextMap.set(name, mf);
					out += '//!#mfunc $name ' + Json.stringify(json) + mfArgs;
					start = q.pos;
				};
				case "#".code: {
					if (p == 0 || q.get(p - 1) == "\n".code) {
						var ctx = q.readContextName(null);
					}
				}; // "#"
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
typedef GmlExtMFuncMagic = (editor:EditCode, reader:GmlReader)->GmlCode;
typedef GmlExtMFuncData = {
	/** ["one", " two"] (incl. spacing around) */
	var args:Array<String>;
	
	/** [1,0,1] for `#mfunc some(a,b) [b,a,b]`*/
	var order:Array<GmlExtMFuncOrder>;
	
	/** Optional - ace token type */
	var ?token:String;
}
abstract GmlExtMFuncOrder(Dynamic) {
	//
	public inline function isPlain():Bool return Std.is(this, Float);
	public inline function asPlain():Int return this;
	//
	public var kind(get, never):GmlExtMFuncOrderKind;
	private inline function get_kind():GmlExtMFuncOrderKind {
		return this[0];
	}
	public inline function asArray():Array<Dynamic> return this;
	//
	public inline function hasArg():Bool {
		return isPlain() || kind != GmlExtMFuncOrderKind.Magic;
	}
	//
	public var arg(get, never):Int;
	private inline function get_arg():Int {
		return this[1];
	}
	//
	public inline function pstr(i:Int):String {
		return this[2 + i];
	}
	//
	public static inline function Plain(arg:Int):GmlExtMFuncOrder {
		return cast arg;
	}
	public static inline function Quoted(arg:Int):GmlExtMFuncOrder {
		return cast ([GmlExtMFuncOrderKind.Quoted, arg]:Array<Dynamic>);
	}
	public static inline function Magic(name:String):GmlExtMFuncOrder {
		return cast ([GmlExtMFuncOrderKind.Magic, name]:Array<Dynamic>);
	}
	public static inline function Pre(arg:Int, pre:String):GmlExtMFuncOrder {
		return cast ([GmlExtMFuncOrderKind.Pre, arg, pre]:Array<Dynamic>);
	}
	public static inline function Post(arg:Int, post:String):GmlExtMFuncOrder {
		return cast ([GmlExtMFuncOrderKind.Post, arg, post]:Array<Dynamic>);
	}
	public static inline function PrePost(arg:Int, pre:String, post:String):GmlExtMFuncOrder {
		return cast ([GmlExtMFuncOrderKind.PrePost, arg, pre, post]:Array<Dynamic>);
	}
	//
}

/** NB: don't change the indexes or existing code will freak out */
enum abstract GmlExtMFuncOrderKind(Int) {
	/** (arg_index) */
	var Plain = 0;
	
	/** (arg_index) */
	var Quoted = 1;
	
	/** (name) */
	var Magic = 2;
	
	/** (arg_index, pre) */
	var Pre = 3;
	
	/** (arg_index, post) */
	var Post = 4;
	
	/** (arg_index, pre, post) */
	var PrePost = 5;
}
