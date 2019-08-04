package parsers.linter;
import tools.Aliases;
import tools.Dictionary;
import editors.EditCode;
import parsers.linter.GmlLinterKind;
import gml.GmlVersion;
import ace.extern.*;
import tools.macros.GmlLinterMacros.*;
import gml.GmlAPI;
using tools.NativeArray;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLinter {
	//
	public var errorText:String = null;
	public var errorPos:AcePos = null;
	function setError(text:String):Void {
		if (errorPos != null) return;
		errorText = text + reader.getStack();
		errorPos = reader.getTopPos();
	}
	//
	public var warnings:Array<GmlLinterWarning> = [];
	function addWarning(text:String):Void {
		warnings.push(new GmlLinterWarning(text + reader.getStack(), reader.getTopPos()));
	}
	//
	
	/** top-level context name */
	var name:String;
	
	var reader:GmlReaderExt;
	
	var editor:EditCode;
	
	var context:String = "";
	
	/** Used for storing stacktrace when reading {...}/[...]/etc. */
	var seqStart:GmlReaderExt = new GmlReaderExt("", none);
	function readSeqStartError(text:String):FoundError {
		if (errorPos != null) return true;
		errorText = text + seqStart.getStack();
		errorPos = seqStart.getTopPos();
		return true;
	}
	
	var version:GmlVersion;
	
	public function new() {
		//
	}
	//{
	var nextKind:GmlLinterKind = KEOF;
	var nextVal(get, set):String;
	function get_nextVal():String {
		if (__nextVal_cache == null) {
			__nextVal_cache = __nextVal_source.substring(__nextVal_start, __nextVal_end);
		}
		return __nextVal_cache;
	}
	inline function set_nextVal(s:String):String {
		return __nextVal_cache = s;
	}
	var __nextVal_cache:String = null;
	var __nextVal_source:String = "";
	var __nextVal_start:Int = 0;
	var __nextVal_end:Int = 0;
	function nextDump():String {
		var v = nextVal;
		if (v != "") {
			return '`$v` (${nextKind.getName()})';
		} else return nextKind.getName();
	}
	//
	function __next_ret(nvk:GmlLinterKind, src:String, nv0:Int, nv1:Int):GmlLinterKind {
		//if (!__next_isPeek) Main.console.log(reader.getTopPosString(), nvk, nvk.getName(), src.substring(nv0, nv1));
		__nextVal_cache = null;
		__nextVal_source = src;
		__nextVal_start = nv0;
		__nextVal_end = nv1;
		nextKind = nvk;
		return nvk;
	}
	function __next_retv(nvk:GmlLinterKind, nv:String):GmlLinterKind {
		//if (!__next_isPeek) Main.console.log(reader.getTopPosString(), nvk, nvk.getName(), nv);
		__nextVal_cache = nv;
		nextKind = nvk;
		return nvk;
	}
	//
	static var keywords:Dictionary<GmlLinterKind> = (function() {
		var q = new Dictionary<GmlLinterKind>();
		q["var"] = KVar;
		q["globalvar"] = KGlobalVar;
		q["enum"] = KEnum;
		//
		q["undefined"] = KUndefined;
		//
		q["not"] = KNot;
		q["and"] = KBoolAnd;
		q["or"] = KBoolOr;
		q["xor"] = KBoolXor;
		//
		q["div"] = KIntDiv;
		q["mod"] = KMod;
		//
		q["if"] = KIf;
		q["then"] = KThen;
		q["else"] = KElse;
		q["return"] = KReturn;
		q["exit"] = KExit;
		//
		q["for"] = KFor;
		q["while"] = KWhile;
		q["do"] = KDo;
		q["until"] = KUntil;
		q["repeat"] = KRepeat;
		q["with"] = KWith;
		q["break"] = KBreak;
		q["continue"] = KContinue;
		//
		q["switch"] = KSwitch;
		q["case"] = KCase;
		q["default"] = KDefault;
		//
		return q;
	})();
	
	//
	var __next_isPeek = false;
	function __next(q:GmlReaderExt):GmlLinterKind {
		var nk:GmlLinterKind;
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
				return __next_ret(nk, _src, p, q.pos);
			}
			inline function retv(nk:GmlLinterKind, nv:String):GmlLinterKind {
				return __next_retv(nk, nv);
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
					q.skipStringAuto(c, version);
					return ret(KString);
				};
				//
				case "?".code: return retv(KQMark, "?");
				case ":".code: return retv(KColon, ":");
				case "@".code: {
					if (version.hasLiteralStrings()) {
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
							case "import", "hyper", "gmcr": {
								q.skipLine();
							};
							case "define", "event", "moment", "target": {
								if (p - 2 <= 0 || q.get(p - 2) == "\n".code) {
									//q.row = 0;
									//q.pos = p;
									context = q.readContextName(null);
									q.skipLine();
								} else {
									q.pos = p; return retv(KHash, "#");
								}
							};
							default: q.pos = p; return retv(KHash, "#");
						}
					} else return retv(KHash, "#");
				};
				case "$".code: {
					start();
					q.skipHex();
					return ret(KNumber);
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
						case "&".code: q.skip(); return retv(KBoolXor, "^^");
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
						case "=".code: q.skip(); return retv(KGE, "<=");
						case "<".code: q.skip(); return retv(KShr, "<<");
						case ">".code: q.skip(); return retv(KNE, "<<");
						default: return retv(KGT, "<");
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
							// todo: imports
							
							//
							var mf = GmlAPI.gmlMFuncs[nv];
							if (mf != null) return retv(KMFunc, nv);
							// expand macros:
							var mcr = GmlAPI.gmlMacros[nv];
							if (mcr != null) {
								if (q.depth > 128) {
									setError("Macro stack overflow");
									return KEOF;
								}
								q.pushSource(mcr.expr, mcr.name);
								break;
							}
							return retv(keywords.defget(nv, KIdent), nv);
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
						setError("Can't parse `" + String.fromCharCode(c) + "`");
						return KEOF;
					}
				};
			}
		}
		start();
		return __next_retv(KEOF, "");
	}
	//
	inline function next():GmlLinterKind {
		return __next(reader);
	}
	//
	private var __peekReader:GmlReaderExt = new GmlReaderExt("", none);
	function peek() {
		var q = __peekReader;
		q.setTo(reader);
		var wasPeek = __next_isPeek;
		__next_isPeek = true;
		var r = __next(q);
		__next_isPeek = wasPeek;
		__skipAvail = true;
		return r;
	}
	var __skipAvail = false;
	function skip() {
		if (__skipAvail) {
			__skipAvail = false;
			reader.setTo(__peekReader);
			return nextKind;
		} else throw "Can't skip - didn't peek";
	}
	function skipIf(cond:Bool) {
		if (cond) {
			reader.setTo(__peekReader);
		}
		__skipAvail = false;
		return cond;
	}
	//
	inline function nextOr(nk:GmlLinterKind):GmlLinterKind {
		return nk != null ? nk : next();
	}
	//}
	function readError(s:String):FoundError {
		setError(s);
		return true;
	}
	function readExpect(s:String):FoundError {
		setError('Expected $s, got ' + nextDump());
		return true;
	}
	
	/** if (next() != kind) error */
	function readCheckSkip(kind:GmlLinterKind, expect:String):FoundError {
		if (next() == kind) return false;
		return readExpect(expect);
	}
	//
	function __readExpr_invalid(flags:Int):FoundError {
		return readExpect((flags & xfAsStat) != 0 ? "a statement" : "an expression");
	}
	
	/** `+¦ a - b;` -> `+ a - b¦;` */
	function readOps():FoundError {
		var q = reader;
		while (q.loop) {
			rc(readExpr(xfNoOps));
			var nk = peek();
			if (nk.isBinOp() || nk == KSet) {
				skip();
			} else break;
		}
		return false;
	}
	function readArgs(sqb:Bool):FoundError {
		var q = reader;
		seqStart.setTo(reader);
		var seenComma = true;
		var closed = false;
		while (q.loop) {
			switch (peek()) {
				case KParClose: {
					if (sqb) return readError("Unexpected `)`");
					skip(); closed = true; break;
				};
				case KSqbClose: {
					if (!sqb) return readError("Unexpected `]`");
					skip(); closed = true; break;
				};
				case KComma: {
					if (seenComma) {
						return readError("Unexpected `,`");
					} else {
						seenComma = true;
						skip();
					}
				};
				default: {
					if (seenComma) {
						seenComma = false;
						rc(readExpr());
					} else return readExpect("a comma in values list");
				};
			}
		}
		if (!closed) {
			return readSeqStartError("Unclosed " + (sqb ? "[]" : "()"));
		} else return false;
	}
	
	static inline var xfNoOps = 1;
	static inline var xfAsStat = 2;
	static inline var xfNoSfx = 4;
	static inline var xfNoSemico = 8;
	function readExpr(flags:Int = 0, ?_nk:GmlLinterKind):FoundError {
		var q = reader;
		var nk:GmlLinterKind = nextOr(_nk);
		//
		inline function invalid():FoundError {
			return __readExpr_invalid(flags);
		}
		if (nk == KEOF) return invalid();
		//
		inline function hasFlag(flag:Int):Bool {
			return (flags & flag) != 0;
		}
		inline function isStat():Bool {
			return hasFlag(xfAsStat);
		}
		var wasStat = isStat();
		// the thing itself:
		var statKind = nk;
		var currKind = nk;
		switch (nk) {
			case KNumber, KString, KUndefined, KIdent: {
				
			};
			case KParOpen: {
				rc(readExpr());
				if (next() != KParClose) return readExpect("a `)`");
			};
			case KInc, KDec, KNot, KBitNot: {
				rc(readExpr());
			};
			case KSqbOpen: rc(readArgs(true));
			case KLambda: rc(readLambda());
			case KMFunc: return GmlLinterMFunc.read(this, flags);
			default: {
				if (nk.isUnOp()) {
					rc(readExpr());
				}
				else return invalid();
			};
		}
		// suffixes:
		while (q.loop) {
			nk = peek();
			switch (nk) {
				case KSet: {
					if (isStat()) {
						skip();
						flags &= ~xfAsStat;
						statKind = KSet;
						rc(readExpr());
					} else {
						if (hasFlag(xfNoOps)) break;
						addWarning("Using single `=` as a comparison operator");
						skip();
						rc(readOps());
						flags |= xfNoSfx;
					}
				};
				case KParOpen: { // fn(...)
					if (!currKind.canCall()) return readError('Expression ${currKind.getName()} isStat not callable');
					if (hasFlag(xfNoSfx)) return readError("Can't call this");
					skip();
					statKind = KCall;
					rc(readArgs(false));
				};
				case KInc, KDec: { // x++, x--
					if (hasFlag(xfNoOps) || hasFlag(xfNoOps)) break;
					if (!currKind.canPostfix()) break;
					skip();
					statKind = currKind = nk;
				};
				case KDot: { // x.y
					skip();
					rc(readCheckSkip(KIdent, "field name after `.`"));
					currKind = KField;
				};
				case KSqbOpen: { // x[i], x[?i], etc.
					skip();
					switch (peek()) {
						case KQMark, KOr: {
							skip();
							rc(readExpr());
						};
						case KHash: {
							skip();
							rc(readExpr());
							rc(readCheckSkip(KComma, "a comma before second index"));
							rc(readExpr());
						};
						case KAtSign: {
							skip();
							rc(readExpr());
							if (skipIf(peek() == KComma)) rc(readExpr());
						};
						default: {
							rc(readExpr());
							if (skipIf(peek() == KComma)) rc(readExpr());
						};
					}
					rc(readCheckSkip(KSqbClose, "a closing `]` in array access"));
					currKind = KArray;
				};
				case KQMark: { // x ? y : z
					if (hasFlag(xfNoOps)) break;
					skip();
					rc(readExpr());
					rc(readCheckSkip(KColon, "a colon in a ?: operator"));
					rc(readExpr());
					currKind = KQMark;
				};
				default: {
					if (nk.isSetOp()) {
						if (!isStat()) return readError("Can't use " + nextDump() + " here.");
						skip();
						currKind = statKind = KSet;
						rc(readExpr());
						flags |= xfNoSfx;
					}
					else if (nk.isBinOp()) {
						if (hasFlag(xfNoOps)) break;
						skip();
						rc(readOps());
						flags |= xfNoSfx;
					}
					else break;
				};
			}
		}
		//
		if (wasStat && !statKind.isStat()) {
			nextKind = statKind;
			nextVal = "";
			return readExpect("a statement");
		}
		return false;
	}
	
	var canBreak = false;
	var canContinue = false;
	function readLoopStat(flags:Int = 0):FoundError {
		var _canBreak = canBreak;
		var _canContinue = canContinue;
		canBreak = true;
		canContinue = true;
		var result = readStat(flags);
		canBreak = _canBreak;
		canContinue = _canContinue;
		return result;
	}
	
	function readSwitch():FoundError {
		rc(readExpr());
		rc(readCheckSkip(KCubOpen, "an opening `{` for switch-block"));
		seqStart.setTo(reader);
		var hasDefault = false;
		var q = reader;
		while (q.loop) {
			switch (peek()) {
				case KCubClose: {
					skip();
					return false;
				};
				case KDefault: {
					skip();
					if (hasDefault) return readError("That's default-case redefinition");
					hasDefault = true;
					rc(readCheckSkip(KColon, "a colon after default-case"));
				};
				case KCase: {
					skip();
					rc(readExpr());
					rc(readCheckSkip(KColon, "a colon after a case"));
				};
				default: {
					rc(readStat());
				};
			}
		}
		return readSeqStartError("Unclosed switch-block");
	}
	function readEnum():FoundError {
		rc(readCheckSkip(KIdent, "an enum name"));
		rc(readCheckSkip(KCubOpen, "an opening `{` for enum"));
		var seenComma = true;
		while (reader.loop) {
			switch (next()) {
				case KCubClose: return false;
				case KIdent: {
					if (!seenComma) return readExpect("a `,` or `}` in enum");
					var nk = peek();
					if (skipIf(nk == KSet)) {
						rc(readExpr());
						nk = peek();
					}
					seenComma = skipIf(nk == KComma);
				};
				default: {
					return readExpect("an enum field or `}`");
				}
			}
		}
		return readSeqStartError("Unclosed {}");
	}
	function readLambda():FoundError {
		skipIf(peek() == KIdent);
		if (skipIf(peek() == KParOpen)) {
			var depth = 1;
			while (reader.loop) {
				switch (next()) {
					case KParOpen: depth++;
					case KParClose: if (--depth <= 0) break;
					default:
				}
			}
		}
		rc(readStat());
		return false;
	}
	
	/**
	 * 
	 */
	function readStat(flags:Int = 0, ?nk:GmlLinterKind):FoundError {
		var q = reader;
		nk = nextOr(nk);
		var mainKind = nk;
		var z:Bool, z2:Bool, i:Int;
		switch (nk) {
			case KMFuncDecl, KMacro: {};
			case KArgs: {};
			case KEnum: rc(readEnum());
			case KVar, KGlobalVar: {
				//z = nk == KArgs;
				seqStart.setTo(reader);
				var found = 0;
				while (q.loop) {
					nk = peek();
					//if (z && nk == KQMark) { skip(); nk = peek(); }
					if (!skipIf(nk == KIdent)) break;
					found++;
					//
					nk = peek();
					if (nk == KColon) { // `name:type`
						skip();
						nk = peek();
						rc(readCheckSkip(nk, "a type name"));
						nk = peek();
					}
					if (nk == KSet) { // `name = val`
						skip();
						rc(readExpr());
					}
					if (!skipIf(peek() == KComma)) break;
				}
				if (found == 0) return readSeqStartError("This `var` has no declarations.");
			};
			case KCubOpen: {
				z = false;
				seqStart.setTo(reader);
				while (q.loop) {
					if (skipIf(peek() == KCubClose)) {
						z = true;
						break;
					}
					rc(readStat());
				}
				if (!z) return readSeqStartError("Unclosed {}");
			};
			case KIf: {
				rc(readExpr());
				skipIf(peek() == KThen);
				if (skipIf(peek() == KSemico)) {
					return readError("You have a semicolon before your then-expression.");
				}
				rc(readStat());
				if (skipIf(peek() == KElse)) rc(readStat());
			};
			case KWhile, KRepeat, KWith: {
				rc(readExpr());
				rc(readLoopStat());
			};
			case KDo: {
				rc(readLoopStat());
				switch (next()) {
					case KUntil, KWhile: rc(readExpr());
					default: return readExpect("an `until` or `while` for a do-loop");
				}
			};
			case KFor: {
				if (next() != KParOpen) return readExpect("a `(` to open a for-loop");
				if (!skipIf(peek() == KSemico)) rc(readStat());
				if (!skipIf(peek() == KSemico)) {
					rc(readExpr());
					skipIf(peek() == KSemico);
				}
				if (!skipIf(peek() == KParClose)) {
					rc(readLoopStat(xfNoSemico));
					if (next() != KParClose) return readExpect("a `)` to close a for-loop");
				}
				rc(readLoopStat());
			};
			case KExit: {};
			case KReturn: {
				switch (peek()) {
					case KSemico, KCubClose: skip(); flags |= xfNoSemico;
					default: rc(readExpr());
				}
			};
			case KBreak: {
				if (!canBreak) return readError("Can't use `break` here");
			};
			case KContinue: {
				if (!canContinue) return readError("Can't use `continue` here");
			};
			case KSwitch: {
				z = canBreak;
				canBreak = true;
				if (readSwitch()) {
					canBreak = z;
					return true;
				} else canBreak = z;
			};
			//
			case KLamDef: rc(readLambda());
			default: {
				rc(readExpr(xfAsStat|flags, nk));
			};
		}
		if (skipIf(peek() == KSemico)) {
			// OK!
		} else if (mainKind.needSemico() && (flags & xfNoSemico) == 0 && q.peek(-1) != ";".code) {
			addWarning("Expected a semicolon after a statement (" + mainKind.getName() + ")");
		}
		return false;
	}
	
	public function run(source:GmlCode, editor:EditCode, version:GmlVersion):FoundError {
		this.version = version;
		var q = reader = new GmlReaderExt(source.trimRight());
		this.name = q.name = editor.file.name;
		this.editor = editor;
		errorText = null;
		var ohno = false;
		while (q.loop) {
			var nk = next();
			if (nk == KEOF) break;
			if (readStat(0, nk)) { ohno = true; break; }
		}
		//
		reader.clear();
		seqStart.clear();
		__peekReader.clear();
		return ohno;
	}
	
	
	public static function runFor(editor:EditCode):FoundError {
		var q = new GmlLinter();
		var session = editor.session;
		if (session.gmlErrorMarkers != null) {
			for (mk in session.gmlErrorMarkers) session.removeMarker(mk);
			session.gmlErrorMarkers.clear();
			session.clearAnnotations();
		}
		var t = Main.window.performance.now();
		var ohno = q.run(session.getValue(), editor, gml.Project.current.version);
		t = (Main.window.performance.now() - t);
		//
		if (session.gmlErrorMarkers == null) session.gmlErrorMarkers = [];
		var annotations:Array<AceAnnotation> = [];
		function addMarker(text:String, pos:AcePos, isError:Bool) {
			var line = session.getLine(pos.row);
			var range = new AceRange(0, pos.row, line.length, pos.row);
			session.gmlErrorMarkers.push(
				session.addMarker(range, isError ? "ace_error-line" : "ace_warning-line", "fullLine")
			);
			annotations.push({
				row: pos.row, column: pos.column, type: isError ? "error" : "warning", text: text
			});
		}
		for (warn in q.warnings) {
			addMarker(warn.text, warn.pos, false);
		}
		var msg:String;
		if (ohno) {
			addMarker(q.errorText, q.errorPos, true);
			msg = q.errorPos.toString() + " " + q.errorText;
		} else {
			msg = "OK! (lint time: " + untyped (t.toFixed(2)) + "ms)";
		}
		Main.window.setTimeout(function() {
			var statusBar = Main.aceEditor.statusBar;
			statusBar.ignoreUntil = Main.window.performance.now() + statusBar.delayTime + 50;
			statusBar.setText(msg);
		}, 50);
		session.setAnnotations(annotations);
		return ohno;
	}
}

class GmlLinterWarning {
	public var text:String;
	public var pos:AcePos;
	public function new(text:String, pos:AcePos) {
		this.text = text;
		this.pos = pos;
	}
}
