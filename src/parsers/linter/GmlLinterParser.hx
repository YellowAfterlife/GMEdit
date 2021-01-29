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
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default: {
						if (q.peek() == "=".code) {
							q.skip();
							return retv(KSetOp, "/=");
						} else return retv(KDiv, "/");
					};
				};
				case '"'.code, "'".code, "`".code: {
					start();
					var rows = q.skipStringAuto(c, l.version);
					if (rows > 0) {
						q.row += rows;
						q.rowStart = q.source.lastIndexOf("\n", q.pos) + 1;
					}
					return ret(KString);
				};
				//
				case "?".code: {
					switch (q.peek()) {
						case "?".code: {
							if (q.peek(1) == "=".code) {
								q.skip(2);
								return retv(KSet, "??=");
							} else {
								q.skip(1);
								return retv(KNullCoalesce, "??");
							}
						};
						case ".".code: {
							c = q.peek(1);
							if (!c.isDigit()) {
								q.skip();
								return retv(KNullDot, "?.");
							} else return retv(KQMark, "?");
						};
						case "[".code: q.skip(); return retv(KNullSqb, "?[");
						default: return retv(KQMark, "?");
					}
				};
				case ":".code: {
					if (q.peek() == "=".code) {
						q.skip();
						return retv(KSet, ":=");
					} else return retv(KColon, ":");
				};
				case "@".code: {
					if (l.version.hasLiteralStrings()) {
						c = q.peek();
						if (c == '"'.code || c == "'".code) {
							start();
							q.skip();
							q.skipString1(c);
							return ret(KString);
						}
					}
					return retv(KAtSign, "@");
				};
				case "#".code: {
					c = q.peek();
					if (c.isHex()) {
						var i = 0, ci;
						while (++i < 6) {
							ci = q.peek(i);
							if (!ci.isHex()) break;
						}
						if (i >= 6) {
							ci = q.peek(i);
							if (!ci.isHex()) {
								q.pos += 6;
								return retv(KNumber, q.substr(p, 7));
							}
						}
					}
					if (c.isIdent0()) {
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
								return ret(nv == "macro" ? KMacro : KMFuncDecl);
							};
							case "args": {
								q.skipLine();
								return retv(KArgs, "#args");
							};
							case "lambda": return retv(KLambda, "#lambda");
							case "lamdef": return retv(KLamDef, "#lamdef");
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
									q.pos = p; return retv(KHash, "#");
								}
							};
							case "gmcr": {
								if (l.keywords["yield"] == null) {
									l.keywords["yield"] = KYield;
									l.keywords["label"] = KLabel;
									l.keywords["goto"] = KGoto;
								}
							};
							case "region", "endregion", "section": {
								q.skipLine();
							};
							default: q.pos = p; return retv(KHash, "#");
						}
					}
					else return retv(KHash, "#");
				};
				case "$".code: {
					start();
					if (q.peek().isHex()) {
						q.skipHex();
						return ret(KNumber);
					} else return retv(KDollar, "$");
				};
				case ";".code: return retv(KSemico, ";");
				case ",".code: return retv(KComma, ",");
				//
				case "(".code: return retv(KParOpen, "(");
				case ")".code: return retv(KParClose, ")");
				case "[".code: return retv(KSqbOpen, "[");
				case "]".code: return retv(KSqbClose, "]");
				case "{".code: return retv(KCubOpen, "{");
				case "}".code: return retv(KCubClose, "}");
				//
				case "=".code: {
					if (q.peek() == "=".code) {
						q.skip();
						return retv(KEQ, "==");
					} else return retv(KSet, "=");
				};
				case "!".code: {
					if (q.peek() == "=".code) {
						q.skip();
						return retv(KNE, "!=");
					} else return retv(KNot, "!");
				};
				//
				case "+".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(KSetOp, "+=");
						case "+".code: q.skip(); return retv(KInc, "++");
						default: return retv(KAdd, "+");
					}
				};
				case "-".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(KSetOp, "-=");
						case "-".code: q.skip(); return retv(KDec, "--");
						case ">".code: q.skip(); return retv(KArrow, "->");
						default: return retv(KSub, "-");
					}
				};
				//
				case "*".code: {
					if (q.peek() == "=".code) {
						q.skip();
						return retv(KSetOp, "*=");
					} else return retv(KMul, "*");
				};
				case "%".code: {
					if (q.peek() == "=".code) {
						q.skip();
						return retv(KSetOp, "%=");
					} else return retv(KMod, "%");
				};
				//
				case "|".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(KSetOp, "|=");
						case "|".code: q.skip(); return retv(KBoolOr, "||");
						default: return retv(KOr, "|");
					}
				};
				case "&".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(KSetOp, "&=");
						case "&".code: q.skip(); return retv(KBoolAnd, "&&");
						default: return retv(KAnd, "&");
					}
				};
				case "^".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(KSetOp, "^=");
						case "^".code: q.skip(); return retv(KBoolXor, "^^");
						default: return retv(KXor, "^");
					}
				};
				case "~".code: return retv(KBitNot, "~");
				//
				case ">".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(KGE, ">=");
						case ">".code: q.skip(); return retv(KShr, ">>");
						default: return retv(KGT, ">");
					}
				};
				case "<".code: {
					switch (q.peek()) {
						case "=".code: q.skip(); return retv(KLE, "<=");
						case "<".code: q.skip(); return retv(KShl, "<<");
						case ">".code: q.skip(); return retv(KNE, "<>");
						default: return retv(KLT, "<");
					}
				};
				//
				case ".".code: {
					c = q.peek();
					if (c.isDigit()) {
						start();
						q.skipNumber(false);
						return ret(KNumber);
					} else return retv(KDot, ".");
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
									if (ir) return KEOF;
									if (ir != null) return next(l, q);
								}
							}
							//
							var mf = GmlAPI.gmlMFuncs[nv];
							if (mf != null) {
								if (GmlLinterMFunc.read(l, q, nv)) return KEOF;
								break;
							}
							// expand macros:
							var mcr = GmlAPI.gmlMacros[nv];
							if (mcr != null) {
								if (q.depth > 128) {
									l.setError("Macro stack overflow");
									return KEOF;
								}
								if (mcr.expr == "var") switch (mcr.name) {
									case "const": return retv(KConst, nv);
									case "let": return retv(KLet, nv);
								}
								q.pushSource(mcr.expr, mcr.name);
								break;
							}
							switch (nv) {
								case "cast":
									if (Preferences.current.castOperators) return retv(KCast, nv);
								case "as":
									if (Preferences.current.castOperators) return retv(KAs, nv);
							}
							return retv(l.keywords.defget(nv, KIdent), nv);
						} while (false);
					}
					else if (c.isDigit()) {
						start();
						if (q.peek() == "x".code) {
							q.skip();
							q.skipHex();
						} else {
							q.skipNumber();
						}
						return ret(KNumber);
					}
					else if (c.code > 32) {
						l.setError("Can't parse `" + String.fromCharCode(c) + "`");
						return KEOF;
					}
				};
			}
		}
		start();
		return l.__next_retv(KEOF, "");
	}
}