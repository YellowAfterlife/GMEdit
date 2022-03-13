package parsers.seeker;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import synext.GmlExtMFunc;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerParser {
	public static function find(seeker:GmlSeekerImpl, flags:GmlSeekerFlags):String {
		var q = seeker.reader;
		var out = seeker.out;
		while (q.loop) {
			var start = q.pos;
			var c = q.read(), s:String;
			switch (c) {
				case "\r".code: if (flags.has(Line)) return "\n";
				case "\n".code: {
					q.row += 1;
					if (flags.has(Line)) return "\n";
				};
				case ",".code: if (flags.has(Comma)) return ",";
				case ".".code: if (flags.has(Period)) return ".";
				case ":".code: if (flags.has(Colon)) return ":";
				case ";".code: if (flags.has(Semico)) return ";";
				case "(".code: if (flags.has(Par0)) return "(";
				case ")".code: if (flags.has(Par1)) return ")";
				case "[".code: if (flags.has(Sqb0)) return "[";
				case "]".code: if (flags.has(Sqb1)) return "]";
				case "{".code: {
					seeker.curlyDepth++;
					if (flags.has(Cub0)) return "{";
				};
				case "}".code: {
					seeker.curlyDepth--;
					if (seeker.subLocalDepth != null && seeker.curlyDepth <= seeker.subLocalDepth) {
						seeker.localKind = "local";
						seeker.subLocalDepth = null;
					}
					if (flags.has(Cub1)) return "}";
				}
				case "=".code: if (flags.has(SetOp) && q.peek() != "=".code) return "=";
				case "/".code: switch (q.peek()) {
					case "/".code: {
						q.skip();
						q.skipLine();
						seeker.commentLineJumps[q.pos - 1] = start;
						if (q.get(start + 2) == "!".code && q.get(start + 3) == "#".code) {
							if (q.substring(start + 4, start + 9) == "mfunc") do {
								//  01234567890
								// `//!#mfunc name
								var c = q.get(start + 9);
								if (!c.isSpace0()) break;
								var line = q.substring(start + 10, q.pos);
								var sp = line.indexOf(" ");
								var name = line.substring(0, sp);
								var json = try {
									haxe.Json.parse(line.substring(sp + 1));
								} catch (_:Dynamic) break;
								var mf = new GmlExtMFunc(name, json);
								seeker.setLookup(name, false, "macro");
								out.mfuncs[name] = mf;
								out.comps[name] = mf.comp;
								out.kindList.push(name);
								var tokenType = ace.AceMacro.jsOrx(json.token, "macro.function");
								out.kindMap.set(name, tokenType);
								var mfd = new GmlFuncDoc(name, name + "(", ")", mf.args, false);
								out.docs[name] = mfd;
							} while (false);
						}
						else if (flags.has(Doc) && q.get(start + 2) == "/".code) {
							return q.substring(start, q.pos);
						}
					};
					case "*".code: {
						q.skip();
						q.skipComment();
						if (flags.has(ComBlock)) {
							return q.substring(start, q.pos);
						}
					};
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: {
					q.skipStringAuto(c, seeker.version);
				};
				case "#".code: {
					q.skipIdent1();
					if (q.pos > start + 1) {
						s = q.substring(start, q.pos);
						switch (s) {
							case "#define","#target": if (flags.has(Define)) {
								if (start == 0) return s;
								c = q.get(start - 1);
								if (c == "\r".code || c == "\n".code) {
									return s;
								}
							};
							case "#region", "#endregion": q.skipLine();
							case "#macro": if (flags.has(Macro)) return s;
							default:
						}
					}
				};
				case "$".code: { // hex literal
					while (q.loopLocal) {
						c = q.peek();
						if (c.isHex()) q.skip();  else break;
					}
				};
				default: {
					if (c.isIdent0()) {
						q.skipIdent1();
						var id = q.substring(start, q.pos);
						var m = ace.AceMacro.jsOrx(out.macros[id], GmlAPI.gmlMacros[id]);
						if (m != null) {
							if (q.depth < 16) {
								q.pushSource(m.expr);
								return find(seeker, flags);
							} else return null;
						} else if (flags.has(Ident)) switch (id) {
							case "let", "const":
								// unfortunately there is no warranty that we'll index
								// let/const macros before we index other files, so let's just
								// assume that `let <ident>` means that you have such a macro.
								var k = q.pos;
								while (q.loopLocal) {
									c = q.get(k);
									if (c.isSpace1()) k++; else break;
								}
								c = q.get(k);
								if (c.isIdent0()) id = "var";
						}
						if (seeker.hasFunctionLiterals && flags.has(Define) && id == "function") return id;
						if (flags.has(Static) && id == "static") return id;
						if (flags.has(Ident)) return id;
					} else if (c.isDigit()) {
						if (q.peek() == "x".code) {
							q.skip();
							while (q.loopLocal) {
								c = q.peek();
								if (c.isHex()) q.skip();  else break;
							}
						} else {
							var seenDot = false;
							while (q.loopLocal) {
								c = q.peek();
								if (c == ".".code) {
									if (!seenDot) {
										seenDot = true;
										q.skip();
									} else break;
								} else if (c.isDigit()) {
									q.skip();
								} else break;
							}
						}
					}
				};
			}
		}
		return null;
	} // find
}

@:build(tools.AutoEnum.build("bit"))
enum abstract GmlSeekerFlags(Int) from Int to Int {
	var Ident;
	var Define;
	/** `#macro` */
	var Macro;
	/** `/// ...` */
	var Doc;
	/** `/* ...` */
	var ComBlock;
	var Cub0;
	var Cub1;
	var Comma;
	var Period;
	var Semico;
	var SetOp;
	var Line;
	var Par0;
	var Par1;
	var Sqb0;
	var Sqb1;
	var Colon;
	var Static;
	//
	public inline function has(flag:GmlSeekerFlags) {
		return this & flag != 0;
	}
}
