package parsers.linter;
import gml.GmlAPI;
import parsers.GmlReaderExt;
import tools.Dictionary;
import parsers.linter.GmlLinterKind.*;
import ui.Preferences;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLinterParser {
	public static function next(l:GmlLinter, q:GmlReaderExt) @:privateAccess
	{
		var nv:String;
		//
		var _src:String;
		inline function start():Void {
			_src = q.source;
		}
		//
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			inline function ret(nk:GmlLinterKind):GmlLinterKind {
				return l.__next_ret(nk, _src, p, q.pos);
			}
			inline function retv(nk:GmlLinterKind, nv:String):GmlLinterKind {
				return l.__next_retv(nk, nv);
			}
			switch (c) {
				case "\n".code: q.markLine();
				case "/".code: switch (q.peek()) {
					case "/".code: {
						q.skip();
						if (q.peek() == "/".code) {
							q.skip();
							q.skipSpaces0_local();
							if (q.peekstr(5) == "@lint" && q.peek(5).isSpace0()) {
								q.skip(5);
								q.skipSpaces0_local();
								var prop = q.readIdent();
								q.skipSpaces0_local();
								var valstr = q.readIdent();
								var val:Bool = switch (valstr) {
									case "true": true;
									case "false": false;
									default: null;
								}
								var f = parsers.linter.misc.GmlLinterJSDocFlag.map[prop];
								if (f != null) f(l, val);
							}
						}
						q.skipLine();
					}
					case "*".code: q.skip(); q.skipComment();
					default: {
						if (q.peek() == "=".code) {
							q.skip();
							return retv(LKSetOp, "/=");
						} else return retv(LKDiv, "/");
					};
				};
				case '"'.code, "'".code, "`".code: {
					start();
					var rows = q.skipStringAuto(c, l.version);
					if (rows > 0) {
						q.row += rows;
						q.rowStart = q.source.lastIndexOf("\n", q.pos) + 1;
					}
					return ret(LKString);
				};
				//
				case "?".code: {
					switch (q.peek()) {
						case "?".code: {
							if (q.peek(1) == "=".code) {
								q.skip(2);
								return retv(LKSet, "??=");
							} else {
								q.skip(1);
								return retv(LKNullCoalesce, "??");
							}
						};
						case ".".code: {
							c = q.peek(1);
							if (!c.isDigit()) {
								q.skip();
								return retv(LKNullDot, "?.");
							} else return retv(LKQMark, "?");
						};
						case "[".code: q.skip(); return retv(LKNullSqb, "?[");
						default: return retv(LKQMark, "?");
					}
				};
				case ":".code: {
					if (q.peek() == "=".code) {
						q.skip();
						return retv(LKSet, ":=");
					} else return retv(LKColon, ":");
				};
				case "@".code: {
					if (l.version.hasLiteralStrings()) {
						c = q.peek();
						if (c == '"'.code || c == "'".code) {
							start();
							q.skip();
							q.skipString1(c);
							return ret(LKString);
						}
					}
					return retv(LKAtSign, "@");
				};
				case "#".code: {
					c = q.peek();
					if (c.isHex()) { // color literal?
						var i = 0, ci;
						while (++i < 6) {
							ci = q.peek(i);
							if (!ci.isHex()) break;
						}
						if (i >= 6) {
							ci = q.peek(i);
							if (!ci.isHex()) {
								q.pos += 6;
								return retv(LKNumber, q.substr(p, 7));
							}
						}
					}
					if (c == '"'.code && l.isProperties) {
						q.skip();
						q.skipString2();
						return retv(LKString, q.substr(p, q.pos));
					}
					else if (c.isIdent0()) {
						p++;
						q.skipIdent1();
						nv = q.substring(p, q.pos);
						switch (nv) {
							case "mfunc", "macro": {
								start();
								while (q.loopLocal) {
									q.skipLine();
									if (q.peek( -1) != "\\".code) break;
									q.skipLineEnd();
									q.markLine();
								}
								return ret(nv == "macro" ? LKMacro : LKMFuncDecl);
							};
							case "args": return retv(LKArgs, "#args");
							case "lambda": return retv(LKLambda, "#lambda");
							case "lamdef": return retv(LKLamDef, "#lamdef");
							case "import", "hyper": {
								q.skipLine();
							};
							case "define", "event", "moment", "target", "action": {
								if (p - 2 <= 0 || q.get(p - 2) == "\n".code) {
									//q.row = 0;
									//q.pos = p;
									q.pos = p;
									if (nv != "action") {
										l.context = q.readContextName(null);
										l.localNamesPerDepth = [];
										l.localKinds = new Dictionary();
										l.isProperties = nv == "event" && l.context == "properties";
									}
									q.skipLine();
								} else {
									q.pos = p; return retv(LKHash, "#");
								}
							};
							case "pragma" if (l.version.config.hasPragma): q.skipLine();
							case "gmcr": {
								if (l.keywords["yield"] == null) {
									l.keywords["yield"] = LKYield;
									l.keywords["label"] = LKLabel;
									l.keywords["goto"] = LKGoto;
								}
								q.skipLine();
							};
							case "region", "endregion", "section": {
								q.skipLine();
							};
							case "with" if (l.version.config.hasEventSections): {
								// todo: #with should change self, but this is hardly used
								q.skipLine();
							}
							default: q.pos = p; return retv(LKHash, "#");
						}
					}
					else return retv(LKHash, "#");
				};
				case "$".code: {
					if (q.isDqTplStart(l.version)) {
						start();
						var rows = q.skipDqTplString(l.version);
						if (rows > 0) {
							q.row += rows;
							q.rowStart = q.source.lastIndexOf("\n", q.pos) + 1;
						}
						return ret(LKString);
					}
					if (q.peek(-2) == '['.code) { // Special case, $ after a [ is always treated as an accessor
						return retv(LKDollar, "$");
					}
					start();
					if (q.peek().isHex()) {
						q.skipHex();
						return ret(LKNumber);
					} else return retv(LKDollar, "$");
				};
				case ";".code: return retv(LKSemico, ";");
				case ",".code: return retv(LKComma, ",");
				//
				case "(".code: return retv(LKParOpen, "(");
				case ")".code: return retv(LKParClose, ")");
				case "[".code: return retv(LKSqbOpen, "[");
				case "]".code: return retv(LKSqbClose, "]");
				case "{".code: return retv(LKCubOpen, "{");
				case "}".code: return retv(LKCubClose, "}");
				//
				case "=".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(LKEQ, "==");
						case ">".code: q.skip(); return retv(LKArrowFunc, "=>");
						default: return retv(LKSet, "=");
					}
				};
				case "!".code: {
					if (q.peek() == "=".code) {
						q.skip();
						return retv(LKNE, "!=");
					} else return retv(LKNot, "!");
				};
				//
				case "+".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(LKSetOp, "+=");
						case "+".code: q.skip(); return retv(LKInc, "++");
						default: return retv(LKAdd, "+");
					}
				};
				case "-".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(LKSetOp, "-=");
						case "-".code: q.skip(); return retv(LKDec, "--");
						case ">".code: q.skip(); return retv(LKArrow, "->");
						default: return retv(LKSub, "-");
					}
				};
				//
				case "*".code: {
					if (q.peek() == "=".code) {
						q.skip();
						return retv(LKSetOp, "*=");
					} else return retv(LKMul, "*");
				};
				case "%".code: {
					if (q.peek() == "=".code) {
						q.skip();
						return retv(LKSetOp, "%=");
					} else return retv(LKMod, "%");
				};
				//
				case "|".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(LKSetOp, "|=");
						case "|".code: q.skip(); return retv(LKBoolOr, "||");
						default: return retv(LKOr, "|");
					}
				};
				case "&".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(LKSetOp, "&=");
						case "&".code: q.skip(); return retv(LKBoolAnd, "&&");
						default: return retv(LKAnd, "&");
					}
				};
				case "^".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(LKSetOp, "^=");
						case "^".code: q.skip(); return retv(LKBoolXor, "^^");
						default: return retv(LKXor, "^");
					}
				};
				case "~".code: return retv(LKBitNot, "~");
				//
				case ">".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(LKGE, ">=");
						case ">".code: q.skip(); return retv(LKShr, ">>");
						default: return retv(LKGT, ">");
					}
				};
				case "<".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(LKLE, "<=");
						case "<".code: q.skip(); return retv(LKShl, "<<");
						case ">".code: q.skip(); return retv(LKNE, "<>");
						default: return retv(LKLT, "<");
					}
				};
				//
				case ".".code: {
					c = q.peek();
					if (c.isDigit()) {
						start();
						q.skipNumber(false);
						return ret(LKNumber);
					} else return retv(LKDot, ".");
				};
				default: {
					if (c.isIdent0()) {
						q.skipIdent1();
						nv = q.substring(p, q.pos);
						do {
							//
							if (nv != "var") {
								var imp = l.editor.imports[l.context];
								if (imp != null) {
									var ir = GmlLinterImports.proc(l, q, p, imp, nv);
									if (ir) return LKEOF;
									if (ir != null) return next(l, q);
								}
							}
							//
							var mf = GmlAPI.gmlMFuncs[nv];
							if (mf != null) {
								if (GmlLinterMFunc.read(l, q, nv)) return LKEOF;
								break;
							}
							// expand macros:
							var mcr = GmlAPI.gmlMacros[nv];
							if (mcr != null) {
								if (q.depth > 128) {
									l.setError("Macro stack overflow");
									return LKEOF;
								}
								if (mcr.expr == "var") switch (mcr.name) {
									case "const": return retv(LKConst, nv);
									case "let": return retv(LKLet, nv);
								}
								var expr = l.macroCache[nv];
								if (expr == null) {
									var imp = synext.GmlExtImport.inst;
									var _on = imp.enabled;
									imp.enabled = false;
									expr = synext.SyntaxExtension.preprocArray(
										l.editor, mcr.expr, file.kind.KGml.syntaxExtensions
									);
									imp.enabled = _on;
									l.macroCache[nv] = expr;
								}
								q.pushSource(expr, mcr.name);
								break;
							}
							switch (nv) {
								case "cast":
									if (Preferences.current.castOperators) return retv(LKCast, nv);
								case "as":
									if (Preferences.current.castOperators) return retv(LKAs, nv);
							}
							return retv(l.keywords.defget(nv, LKIdent), nv);
						} while (false);
					}
					else if (c.isDigit()) {
						start();
						if (c == "0".code && q.peek() == "x".code) {
							q.skip();
							q.skipHex();
						}
						else if (c == "0".code && q.peek() == "b".code) {
							q.skip();
							q.skipBinary();
						}
						else {
							q.skipNumber();
						}
						return ret(LKNumber);
					}
					else if (c.code > 32) {
						l.setError("Can't parse `" + String.fromCharCode(c) + "` (" + c + ")");
						return LKEOF;
					}
				};
			}
		}
		start();
		return l.__next_retv(LKEOF, "");
	}
}