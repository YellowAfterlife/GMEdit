package parsers.linter;
import ace.AceGmlContextResolver;
import ace.AceGmlTools;
import gml.GmlFuncDoc;
import gml.GmlImports;
import gml.GmlLocals;
import gml.GmlNamespace;
import gml.GmlTypeName;
import gml.Project;
import parsers.linter.GmlLinterInit;
import synext.GmlExtLambda;
import tools.Aliases;
import tools.Dictionary;
import editors.EditCode;
import parsers.linter.GmlLinterKind;
import gml.GmlVersion;
import ace.extern.*;
import tools.JsTools;
import tools.macros.GmlLinterMacros.*;
import gml.GmlAPI;
using tools.NativeArray;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLinter {
	
	public static function getOption(fn:GmlLinterPrefs->Bool):Bool {
		var lp = gml.Project.current.properties.linterPrefs;
		var r:Bool = null;
		for (_ in 0 ... 1) {
			if (lp != null) {
				r = fn(lp);
				if (r != null) break;
			}
			r = fn(ui.Preferences.current.linterPrefs);
			if (r != null) break;
			r = fn(GmlLinterPrefs.defValue);
		}
		return r;
	}
	//
	public var errorText:String = null;
	public var errorPos:AcePos = null;
	function setError(text:String):Void {
		if (errorPos != null) return;
		errorText = text + reader.getStack();
		errorPos = reader.getTopPos();
	}
	//
	public var warnings:Array<GmlLinterProblem> = [];
	function addWarning(text:String):Void {
		warnings.push(new GmlLinterProblem(text + reader.getStack(), reader.getTopPos()));
	}
	public var errors:Array<GmlLinterProblem> = [];
	function addError(text:String):Void {
		errors.push(new GmlLinterProblem(text + reader.getStack(), reader.getTopPos()));
	}
	//
	
	/** top-level context name */
	var name:String;
	
	var reader:GmlReaderExt;
	
	var editor:EditCode;
	
	var context:String = "";
	inline function getImports():GmlImports {
		return editor.imports[context];
	}
	
	var __selfType_set = false;
	var __selfType_type:GmlTypeName = null;
	function getSelfType() {
		if (__selfType_set) return __selfType_type;
		return AceGmlTools.getSelfType({ session: editor.session, scope: context });
	}
	
	var __otherType_set = false;
	var __otherType_type:GmlTypeName = null;
	function getOtherType() {
		if (__otherType_set) return __otherType_type;
		return AceGmlTools.getOtherType({ session: editor.session, scope: context });
	}
	
	/** depth -> null<variables that should be freed after this depth> */
	var localNamesPerDepth:Array<Array<String>> = [];
	var localKinds:Dictionary<GmlLinterKind> = new Dictionary();
	
	var isProperties:Bool = false;
	
	/** Used for storing stacktrace when reading {...}/[...]/etc. */
	var seqStart:GmlReaderExt = new GmlReaderExt("", GmlVersion.none);
	function readSeqStartError(text:String):FoundError {
		if (errorPos != null) return true;
		errorText = text + seqStart.getStack();
		errorPos = seqStart.getTopPos();
		return true;
	}
	function readSeqStartWarn(text:String):FoundError {
		if (errorPos != null) return true;
		warnings.push(new GmlLinterProblem(text + seqStart.getStack(), seqStart.getTopPos()));
		return true;
	}
	
	var version:GmlVersion;
	
	var optForbidNonIdentCalls:Bool;
	
	var optRequireSemico:Bool;
	var optNoSingleEqu:Bool;
	var optRequireParentheses:Bool;
	var optBlockScopedVar:Bool;
	var optRequireFunctions:Bool;
	var optCheckHasReturn:Bool;
	var optBlockScopedCase:Bool;
	var optCheckScriptArgumentCounts:Bool;
	
	public function new() {
		optRequireSemico = getOption((q) -> q.requireSemicolons);
		optNoSingleEqu = getOption((q) -> q.noSingleEquals);
		optRequireParentheses = getOption((q) -> q.requireParentheses);
		optBlockScopedVar = getOption((q) -> q.blockScopedVar);
		optBlockScopedCase = getOption((q) -> q.blockScopedCase);
		optRequireFunctions = getOption((q) -> q.requireFunctions);
		optCheckHasReturn = getOption((q) -> q.checkHasReturn);
		optCheckScriptArgumentCounts = getOption((q) -> q.checkScriptArgumentCounts);
		optForbidNonIdentCalls = !GmlAPI.stdKind.exists("method");
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
	var keywords:Dictionary<GmlLinterKind>;
	function initKeywords() {
		keywords = GmlLinterInit.keywords(this);
	}
	
	//
	var __next_isPeek = false;
	inline function __next(q:GmlReaderExt):GmlLinterKind {
		return GmlLinterParser.next(this, q);
	}
	//
	inline function next():GmlLinterKind {
		return __next(reader);
	}
	//
	private var __peekReader:GmlReaderExt = new GmlReaderExt("", GmlVersion.none);
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
	function __readExpr_invalid(flags:GmlLinterReadFlags):FoundError {
		return readExpect(flags.has(AsStat) ? "a statement" : "an expression");
	}
	
	/** `+¦ a - b;` -> `+ a - b¦;` */
	function readOps(oldDepth:Int):FoundError {
		var newDepth = oldDepth + 1;
		var q = reader;
		while (q.loop) {
			rc(readExpr(newDepth, NoOps));
			var nk = peek();
			if (nk.isBinOp() || nk == KSet) {
				skip();
			} else break;
		}
		return false;
	}
	
	/**
	 * 
	 * @param	sqb Whether this is a [...args]
	 * @return	number of arguments read, -1 on error
	 */
	function readArgs(oldDepth:Int, sqb:Bool):Int {
		var newDepth = oldDepth + 1;
		var q = reader;
		seqStart.setTo(reader);
		var seenComma = true;
		var closed = false;
		var argc = 0;
		var itemType:GmlTypeName = null;
		while (q.loop) {
			switch (peek()) {
				case KParClose: {
					if (sqb) { readError("Unexpected `)`"); return -1; }
					skip(); closed = true; break;
				};
				case KSqbClose: {
					if (!sqb) { readError("Unexpected `]`"); return -1; }
					skip(); closed = true; break;
				};
				case KComma: {
					if (seenComma) {
						readError("Unexpected `,`");
						return -1;
					} else {
						seenComma = true;
						skip();
					}
				};
				default: {
					if (seenComma) {
						seenComma = false;
						if (readExpr(newDepth)) return -1;
						if (itemType == null) itemType = readExpr_currType;
						argc++;
					} else {
						readExpect("a comma in values list");
						return -1;
					}
				};
			}
		}
		readArgs_itemType = itemType;
		if (!closed) {
			readSeqStartError("Unclosed " + (sqb ? "[]" : "()"));
			return -1;
		} else return argc;
	}
	var readArgs_itemType:GmlTypeName;
	
	function checkCallArgs(doc:GmlFuncDoc, currName:String, argc:Int, isExpr:Bool, isNew:Bool) {
		var isUserFunc:Bool;
		if (currName == null) {
			isUserFunc = true;
			currName = "an anonymous function";
		} else isUserFunc = !GmlAPI.stdDoc.exists(currName);
		
		// figure out min/max argument counts:
		var minArgs:Int, maxArgs:Int;
		if (doc != null) {
			minArgs = doc.minArgs;
			maxArgs = doc.maxArgs;
			
			// also check for other problems while we are here:
			if (doc.isConstructor) {
				if (!isNew) addWarning('`$currName` is a constructor, but is not used via `new`');
			} else {
				if (isNew) {
					addWarning('`$currName` is not a constructor, but is being used via `new`');
				}
				if (isExpr && optCheckHasReturn && doc.hasReturn == false) {
					addWarning('`$currName` does not return anything, the result is unspecified');
				}
			}
		} else {
			// perhaps it's a hidden extension function? we don't add them to extDoc
			minArgs = GmlAPI.extArgc[currName];
			if (minArgs == null) {
				if (optRequireFunctions && optForbidNonIdentCalls) {
					addWarning('`$currName` doesn\'t seem to be a valid function');
				}
				return;
			}
			if (minArgs < 0) {
				minArgs = 0;
				maxArgs = 0x7fffffff;
			} else maxArgs = minArgs;
		}
		//
		if (isUserFunc && !optCheckScriptArgumentCounts) {
			// OK!
		} else if (argc < minArgs) {
			if (maxArgs == minArgs) {
				addError('Not enough arguments for $currName (expected $minArgs, got $argc)');
			} else if (maxArgs >= 0x7fffffff) {
				addError('Not enough arguments for $currName (expected $minArgs+, got $argc)');
			} else {
				addError('Not enough arguments for $currName (expected $minArgs..$maxArgs, got $argc)');
			}
		} else if (argc > maxArgs) {
			if (minArgs == maxArgs) {
				addError('Too many arguments for $currName (expected $maxArgs, got $argc)');
			} else {
				addError('Too many arguments for $currName (expected $minArgs..$maxArgs, got $argc)');
			}
		}
	}
	
	var readExpr_currKind:GmlLinterKind;
	var readExpr_currName:GmlName;
	var readExpr_currType:GmlTypeName;
	var readExpr_currFunc:GmlFuncDoc;
	function readExpr_checkConst(currName:GmlName, currKind:GmlLinterKind) {
		switch (currKind) {
			case KIdent: {
				if (localKinds[currName] == KConst) {
					addWarning('Assigning to a `const` local `$currName`');
				}
			};
			case KNullField, KNullArray: {
				addError("Null-conditional values cannot be assigned to");
			};
			default:
		}
	}
		
	function readExpr(oldDepth:Int, flags:GmlLinterReadFlags = None, ?_nk:GmlLinterKind):FoundError {
		var newDepth = oldDepth + 1;
		var q = reader;
		var nk:GmlLinterKind = nextOr(_nk);
		//
		inline function invalid():FoundError {
			return __readExpr_invalid(flags);
		}
		if (nk == KEOF) return invalid();
		//
		inline function hasFlag(flag:GmlLinterReadFlags):Bool {
			return flags.has(flag);
		}
		inline function isStat():Bool {
			return hasFlag(AsStat);
		}
		var wasStat = isStat();
		// the thing itself:
		var statKind = nk;
		var currKind = nk;
		var currName = nk == KIdent ? nextVal : null;
		var currType:GmlTypeName = null;
		var currFunc:GmlFuncDoc = null;
		//
		inline function checkConst():Void {
			readExpr_checkConst(currName, currKind);
		}
		//
		switch (nk) {
			case KNumber: currType = GmlTypeName.number;
			case KString: currType = GmlTypeName.string;
			case KUndefined: // OK!
			case KIdent: {
				if (hasFlag(HasPrefix)) checkConst();
				if (localKinds[currName] == KGhostVar) {
					addWarning('Trying to access a variable `$currName` outside of its scope');
				}
				// linting #properties:
				if (isProperties && isStat()) {
					if (skipIf(peek() == KColon)) { // name:type
						rc(readCheckSkip(KIdent, "variable type"));
						if (skipIf(peek() == KLT)) {
							// we know that it's valid or else GmlObjectProperties would prevent you from saving
							var depth = 1;
							while (q.loop) {
								switch (next()) {
									case KLT: depth++;
									case KGT: if (--depth <= 0) break;
									default:
								}
							}
						}
					}
				}
				// figure out what this is:
				var locals:GmlLocals, ns:GmlNamespace, imp:GmlImports, lam:GmlExtLambda;
				if (currName == "self") {
					currType = getSelfType();
					currFunc = currType.getSelfCallDoc(getImports());
				} else if (currName == "other") {
					currType = getOtherType();
					currFunc = currType.getSelfCallDoc(getImports());
				} else if (JsTools.nca(locals = editor.locals[context], locals.kind.exists(currName))) {
					imp = getImports();
					if (imp != null) {
						currType = GmlTypeName.fromString(imp.localTypes[currName]);
						if (currType != null) {
							currFunc = AceGmlTools.findNamespace(currType, imp, function(ns) {
								return ns.docInstMap[""];
							});
						}
					}
				} else if (JsTools.nca(lam = editor.lambdas[context], lam.kind.exists(currName))) {
					currFunc = lam.docs[currName];
				} else if (GmlAPI.gmlKind[currName] == "asset.object") {
					currType = GmlTypeName.fromString(currName);
				} else if (JsTools.nca(imp = getImports(), ns = imp.namespaces[currName]) != null) {
					currType = GmlTypeName.type(GmlTypeName.fromString(currName));
					currFunc = ns.docStaticMap[""];
				} else if ((ns = GmlAPI.gmlNamespaces[currName]) != null) {
					currType = GmlTypeName.type(GmlTypeName.fromString(currName));
					currFunc = ns.docStaticMap[""];
				} else {
					currFunc = AceGmlTools.findGlobalFuncDoc(currName);
					if (currFunc == null) {
						var t = getSelfType();
						if (t != null) AceGmlTools.findNamespace(t, getImports(), function(ns:GmlNamespace) {
							if (ns.instKind.exists(currName)) {
								currType = ns.getInstType(currName);
								currFunc = ns.getInstDoc(currName);
								return true;
							} else return false;
						});
					}
				}
			};
			case KParOpen: {
				rc(readExpr(newDepth));
				if (next() != KParClose) return readExpect("a `)`");
				currType = readExpr_currType;
				currFunc = readExpr_currFunc;
			};
			case KNew: {
				rc(readExpr(newDepth, IsNew));
				currType = GmlTypeName.fromString(readExpr_currName);
				currFunc = currType.getSelfCallDoc(getImports());
			};
			case KNot, KBitNot: {
				rc(readExpr(newDepth));
				currType = nk == KNot ? GmlTypeName.bool : GmlTypeName.number;
			};
			case KInc, KDec: {
				rc(readExpr(newDepth, HasPrefix));
				currType = GmlTypeName.number;
			};
			case KSqbOpen: {
				rc(readArgs(newDepth, true) < 0);
				currType = readArgs_itemType;
				currType = JsTools.nca(currType, GmlTypeName.array(currType));
			};
			case KLambda: rc(readLambda(newDepth, false)); currFunc = readLambda_doc;
			case KFunction: rc(readLambda(newDepth, true)); currFunc = readLambda_doc;
			case KCubOpen: { // { fd1: v1, fd2: v2 }
				if (skipIf(peek() == KCubClose)) {
					// empty!
				} else while (q.loop) {
					switch (next()) {
						case KIdent, KString: { };
						case KCubClose: break;
						default: return readExpect("a field name");
					}
					rc(readCheckSkip(KColon, "a `:` between key-value pair in {}"));
					rc(readExpr(newDepth));
					switch (peek()) {
						case KCubClose: skip(); break;
						case KComma: skip();
						default: return readExpect("a `,` or a `}` after a key-value pair in {}");
					}
				}
			};
			default: {
				if (nk.isUnOp()) { // +v or -v
					rc(readExpr(newDepth));
					currType = GmlTypeName.number;
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
						checkConst();
						skip();
						flags.remove(AsStat);
						statKind = KSet;
						rc(readExpr(newDepth));
						currType = null;
					} else {
						if (hasFlag(NoOps)) break;
						if (optNoSingleEqu) {
							addWarning("Using single `=` as a comparison operator");
						}
						skip();
						rc(readOps(newDepth));
						flags.add(NoSfx);
						currType = GmlTypeName.bool;
					}
				};
				case KParOpen: { // fn(...)
					if (optForbidNonIdentCalls && !currKind.canCall()) {
						return readError('Expression ${currKind.getName()} is not callable');
					}
					if (hasFlag(NoSfx)) return readError("Can't call this");
					skip();
					var argc = readArgs(newDepth, false);
					rc(argc < 0);
					if (currFunc != null) {
						checkCallArgs(currFunc, currName, argc, !isStat(), hasFlag(IsNew));
					}
					statKind = currKind = KCall;
					currType = JsTools.nca(currFunc, currFunc.returnType);
					currFunc = currType.getSelfCallDoc(getImports());
				};
				case KInc, KDec: { // x++, x--
					if (hasFlag(NoSfx)) break;
					if (!currKind.canPostfix()) break;
					checkConst();
					skip();
					statKind = currKind = nk;
					currType = GmlTypeName.number;
				};
				case KDot, KNullDot: { // x.y
					skip();
					rc(readCheckSkip(KIdent, "field name after `.`"));
					currKind = nk == KDot ? KField : KNullField;
					if (currType != null) {
						var isStatic = currType.isType;
						var nsType = isStatic ? currType.unwrapParam() : currType;
						AceGmlTools.findNamespace(currType, getImports(), function(ns) {
							if (isStatic) {
								currType = ns.staticTypes[nextVal];
								currFunc = ns.docStaticMap[nextVal];
							} else {
								currType = ns.getInstType(nextVal);
								currFunc = ns.getInstDoc(nextVal);
							}
							return currType != null || currFunc != null;
						});
					}
				};
				case KSqbOpen, KNullSqb: { // x[i], x[?i], etc.
					skip();
					var isNull = nk == KNullSqb;
					var isArray = false;
					var isLiteral = false;
					switch (peek()) {
						case KQMark, KOr, KDollar: { // map[?k], list[|i], struct[$k]
							skip();
							rc(readExpr(newDepth));
						};
						case KHash: { // grid[#x, y]
							skip();
							rc(readExpr(newDepth));
							rc(readCheckSkip(KComma, "a comma before second index"));
							rc(readExpr(newDepth));
						};
						case KAtSign: { // array[@i] or array[@i, k]
							skip();
							rc(readExpr(newDepth));
							if (skipIf(peek() == KComma)) rc(readExpr(newDepth));
							if (JsTools.nca(currType, currType.isArray)) {
								currType = currType.unwrapParam();
							}
						};
						default: { // array[i] or array[i, k]
							isArray = true;
							rc(readExpr(newDepth));
							if (skipIf(peek() == KComma)) rc(readExpr(newDepth));
							if (isNull && skipIf(peek() == KComma)) { // whoops, a?[b,c,d]
								readArgs(newDepth, true);
								isLiteral = true;
							} else {
								if (JsTools.nca(currType, currType.isArray)) {
									currType = currType.unwrapParam();
								}
							}
						};
					}
					if (!isLiteral) rc(readCheckSkip(KSqbClose, "a closing `]` in array access"));
					if (isLiteral) {
						rc(readCheckSkip(KColon, "a colon in a ?: operator"));
						rc(readExpr(newDepth));
						currKind = KQMark;
					} else if (isNull && isArray && peek() == KColon) { // whoops, a?[b]:c
						skip();
						rc(readExpr(newDepth));
						currKind = KQMark;
					} else {
						currKind = isNull ? KNullArray : KArray;
					}
				};
				case KLiveIn: { // field in object
					if (hasFlag(NoOps)) break;
					skip();
					rc(readExpr(newDepth));
					currKind = KLiveIn;
				};
				case KNot: { // field not in object
					if (hasFlag(NoOps) || keywords["in"] == null) break;
					seqStart.setTo(reader);
					skip();
					if (!skipIf(peek() == KLiveIn)) {
						reader.setTo(seqStart);
						break;
					}
					rc(readExpr(newDepth));
					currKind = KLiveIn;
				};
				case KQMark: { // x ? y : z
					if (hasFlag(NoOps)) break;
					skip();
					rc(readExpr(newDepth));
					rc(readCheckSkip(KColon, "a colon in a ?: operator"));
					rc(readExpr(newDepth));
					currKind = KQMark;
				};
				case KNullCoalesce: { // x ?? y
					if (hasFlag(NoOps)) break;
					skip();
					rc(readExpr(newDepth));
					currKind = KNullCoalesce;
				};
				default: {
					if (nk.isSetOp()) {
						if (!isStat()) return readError("Can't use " + nextDump() + " here.");
						checkConst();
						skip();
						currKind = statKind = KSet;
						rc(readExpr(newDepth));
						flags.add(NoSfx);
					}
					else if (nk.isBinOp()) {
						if (hasFlag(NoOps)) break;
						skip();
						rc(readOps(newDepth));
						flags.add(NoSfx);
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
		readExpr_currName = currKind == KIdent ? currName : null;
		readExpr_currKind = currKind;
		readExpr_currType = currType;
		readExpr_currFunc = currFunc;
		return false;
	}
	
	function discardBlockScopes(newDepth:Int):Void {
		while (localNamesPerDepth.length > newDepth) {
			var arr = localNamesPerDepth.pop();
			if (arr != null) {
				for (name in arr) localKinds[name] = KGhostVar;
			}
		}
	}
	
	var canBreak = false;
	var canContinue = false;
	function readLoopStat(oldDepth:Int, flags:GmlLinterReadFlags = None):FoundError {
		var _canBreak = canBreak;
		var _canContinue = canContinue;
		canBreak = true;
		canContinue = true;
		var result = readStat(oldDepth + 1, flags);
		canBreak = _canBreak;
		canContinue = _canContinue;
		return result;
	}
	
	function readSwitch(oldDepth:Int):FoundError {
		var newDepth = oldDepth + 1;
		rc(readCheckSkip(KCubOpen, "an opening `{` for switch-block"));
		//
		var isInCase = false;
		inline function resetCase():Void {
			if (isInCase) {
				if (optBlockScopedCase) discardBlockScopes(newDepth);
				isInCase = false;
			}
		}
		//
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
					resetCase();
				};
				case KCase: {
					skip();
					rc(readExpr(newDepth));
					rc(readCheckSkip(KColon, "a colon after a case"));
					resetCase();
				};
				default: {
					isInCase = true;
					rc(readStat(newDepth));
				};
			}
		}
		return readSeqStartError("Unclosed switch-block");
	}
	function readEnum(oldDepth:Int):FoundError {
		var newDepth = oldDepth + 1;
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
						rc(readExpr(newDepth));
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
	
	static var readLambda_doc:GmlFuncDoc;
	function readLambda(oldDepth:Int, isFunc:Bool):FoundError {
		var name = "function";
		if (peek() == KIdent) {
			skip();
			name = nextVal;
		}
		var doc = new GmlFuncDoc(name, "(", ")", [], false);
		if (skipIf(peek() == KParOpen)) { // (...args)
			var depth = 1;
			var awaitArgName = true;
			while (reader.loop) {
				switch (next()) {
					case KParOpen: depth++;
					case KParClose: if (--depth <= 0) break;
					case KIdent: {
						if (awaitArgName) {
							awaitArgName = false;
							doc.args.push(nextVal);
						}
					};
					case KComma: if (depth == 1) awaitArgName = true;
					default:
				}
			}
		} else if (isFunc) return readExpect("function literal arguments");
		//
		if (isFunc && skipIf(peek() == KColon)) { // : 
			readCheckSkip(KIdent, "a parent type name");
			readCheckSkip(KParOpen, "opening bracket");
			rc(readArgs(oldDepth + 1, false) < 0);
		}
		if (isFunc) {
			skipIf(peek() == KIdent && nextVal == "constructor");
		}
		//
		var oldLocalNames = localNamesPerDepth;
		var oldLocalKinds = localKinds;
		localNamesPerDepth = [];
		localKinds = new Dictionary();
		rc(readStat(0));
		localNamesPerDepth = oldLocalNames;
		localKinds = oldLocalKinds;
		readLambda_doc = doc;
		return false;
	}
	
	/**
	 * 
	 */
	function readStat(oldDepth:Int, flags:GmlLinterReadFlags = None, ?_nk:GmlLinterKind):FoundError {
		var newDepth = oldDepth + 1;
		var q = reader;
		var nk:GmlLinterKind = nextOr(_nk);
		var mainKind = nk;
		var z:Bool, z2:Bool, i:Int;
		inline function checkParens():Void {
			if (optRequireParentheses && readExpr_currKind != KParOpen) {
				addWarning("Expression is missing parentheses");
			}
		}
		switch (nk) {
			case KMFuncDecl, KMacro: {};
			case KArgs: {};
			case KEnum: rc(readEnum(newDepth));
			case KVar, KConst, KLet, KGlobalVar: {
				//z = nk == KArgs;
				seqStart.setTo(reader);
				var found = 0;
				while (q.loop) {
					nk = peek();
					//if (z && nk == KQMark) { skip(); nk = peek(); }
					if (!skipIf(nk == KIdent)) break;
					if (mainKind != KGlobalVar) {
						var name = nextVal;
						if (mainKind != KVar || optBlockScopedVar) {
							var lk = localKinds[name];
							if (lk != null && lk != KGhostVar) {
								addWarning('Redefinition of a variable `$name`');
							} else {
								var arr = localNamesPerDepth[oldDepth];
								if (arr == null) {
									arr = [];
									localNamesPerDepth[oldDepth] = arr;
								}
								arr.push(name);
							}
						}
						localKinds[name] = mainKind;
					}
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
						rc(readExpr(newDepth));
					}
					if (!skipIf(peek() == KComma)) break;
				}
				if (found == 0) readSeqStartWarn("This `var` has no declarations.");
			};
			case KCubOpen: {
				z = false;
				seqStart.setTo(reader);
				while (q.loop) {
					if (skipIf(peek() == KCubClose)) {
						z = true;
						break;
					}
					rc(readStat(newDepth));
				}
				if (!z) return readSeqStartError("Unclosed {}");
			};
			case KSemico: {
				if (optRequireSemico) {
					addWarning("Stray semicolon");
				}
			};
			case KIf: {
				rc(readExpr(newDepth));
				checkParens();
				skipIf(peek() == KThen);
				if (skipIf(peek() == KSemico)) {
					return readError("You have a semicolon before your then-expression.");
				}
				rc(readStat(newDepth));
				if (skipIf(peek() == KElse)) rc(readStat(newDepth));
			};
			case KWhile, KRepeat, KWith: {
				rc(readExpr(newDepth));
				checkParens();
				rc(readLoopStat(newDepth));
			};
			case KDo: {
				rc(readLoopStat(newDepth));
				switch (next()) {
					case KUntil, KWhile: {
						rc(readExpr(newDepth));
						checkParens();
					};
					default: return readExpect("an `until` or `while` for a do-loop");
				}
			};
			case KFor: {
				if (next() != KParOpen) return readExpect("a `(` to open a for-loop");
				if (!skipIf(peek() == KSemico)) rc(readStat(newDepth));
				if (!skipIf(peek() == KSemico)) {
					rc(readExpr(newDepth));
					skipIf(peek() == KSemico);
				}
				if (!skipIf(peek() == KParClose)) {
					rc(readLoopStat(newDepth, NoSemico));
					if (next() != KParClose) return readExpect("a `)` to close a for-loop");
				}
				rc(readLoopStat(newDepth));
			};
			case KExit: {};
			case KReturn: {
				switch (peek()) {
					case KSemico, KCubClose: skip(); flags.add(NoSemico);
					default: rc(readExpr(newDepth));
				}
			};
			case KBreak: {
				if (!canBreak) addError("Can't use `break` here");
			};
			case KContinue: {
				if (!canContinue) addError("Can't use `continue` here");
			};
			case KSwitch: {
				z = canBreak;
				canBreak = true;
				rc(readExpr(newDepth));
				checkParens();
				if (readSwitch(newDepth)) {
					canBreak = z;
					return true;
				} else canBreak = z;
			};
			//
			case KLiveWait, KYield, KGoto, KThrow, KDelete: { // keyword <value>
				rc(readExpr(newDepth));// wait <time>
			}
			case KLabel: { // label <name>[:]
				switch (peek()) {
					case KIdent, KString: {
						skip();
					};
					default: return readExpect("a label name");
				}
				skipIf(peek() == KColon);
			};
			case KStatic: {
				rc(readCheckSkip(KIdent, "a variable name"));
				rc(readCheckSkip(KSet, "a `=` after static variable name"));
				rc(readExpr(newDepth, flags));
			};
			case KTry: {
				rc(readStat(newDepth));
				rc(readCheckSkip(KCatch, "a `catch` after a `try` block"));
				rc(readExpr(newDepth));
				rc(readStat(newDepth)); // catch-block
				if (skipIf(peek() == KFinally)) {
					rc(readStat(newDepth));
				}
			};
			//
			case KLamDef: rc(readLambda(newDepth, false));
			default: {
				rc(readExpr(newDepth, flags.with(AsStat), nk));
			};
		}
		//
		if (skipIf(peek() == KSemico)) {
			// OK!
		} else if (optRequireSemico && mainKind.needSemico() && !flags.has(NoSemico)) {
			switch (q.peek( -1)) {
				case ";".code, "}".code: {}; // allowed
				default: {
					addWarning('Expected a semicolon after a statement (${mainKind.getName()})');
				};
			}
		}
		//
		discardBlockScopes(newDepth);
		//
		return false;
	}
	
	public function runPre(source:GmlCode, editor:EditCode, version:GmlVersion) {
		this.version = version;
		initKeywords();
		var q = reader = new GmlReaderExt(source.trimRight());
		this.name = q.name = editor.file.name;
		this.editor = editor;
		errorText = null;
	}
	public function runPost() {
		reader.clear();
		seqStart.clear();
		__peekReader.clear();
	}
	
	/**
	 * 
	 * @return Whether there was a syntax error, among other things
	 */
	public function run(source:GmlCode, editor:EditCode, version:GmlVersion):FoundError {
		runPre(source, editor, version);
		var q = reader;
		var ohno = false;
		while (q.loop) {
			var nk = next();
			if (nk == KEOF) break;
			if (readStat(0, None, nk)) {
				errors.push(new GmlLinterProblem(errorText, errorPos));
				ohno = true;
				break;
			}
		}
		runPost();
		return ohno;
	}
	
	
	public static function runFor(editor:EditCode, ?code:GmlCode):FoundError {
		var q = new GmlLinter();
		var session = editor.session;
		if (session.gmlErrorMarkers != null) {
			for (mk in session.gmlErrorMarkers) session.removeMarker(mk);
			session.gmlErrorMarkers.clear();
			session.clearAnnotations();
		}
		var t = Main.window.performance.now();
		if (code == null) code = session.getValue();
		var ohno = q.run(code, editor, gml.Project.current.version);
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
		for (warn in q.warnings) addMarker(warn.text, warn.pos, false);
		for (error in q.errors) addMarker(error.text, error.pos, true);
		//
		var msg:String;
		if (q.warnings.length == 0 && q.errors.length == 0) {
			msg = "OK!";
		} else {
			if (ohno) {
				msg = "⛔"; // 🚔
			} else if (q.errors.length > 0) {
				msg = "🛑"; // 🚒
			} else msg = "⚠";
			if (q.errors.length > 0) {
				msg += q.errors.length + " error";
				if (q.errors.length != 1) msg += "s";
			}
			if (q.warnings.length > 0) {
				if (q.errors.length > 0) msg += ", ";
				msg += q.warnings.length + " warning";
				if (q.warnings.length != 1) msg += "s";
			}
			msg += "!";
		}
		msg += " (lint time: " + untyped (t.toFixed(2)) + "ms)";
		//
		Main.window.setTimeout(function() {
			var statusBar = Main.aceEditor.statusBar;
			statusBar.ignoreUntil = Main.window.performance.now() + statusBar.delayTime + 50;
			statusBar.setText(msg);
		}, 50);
		session.setAnnotations(annotations);
		return ohno;
	}
	
	public static function getType(expr:String, editor:EditCode, context:String, pos:AcePos):GmlLinterTypeInfo {
		var q = new GmlLinter();
		q.context = context;
		q.runPre(expr, editor, Project.current.version);
		if (pos != null) {
			var types = AceGmlContextResolver.run(editor.session, pos);
			Console.log(types);
			q.__selfType_set = true;
			q.__selfType_type = types.self;
			q.__otherType_set = true;
			q.__otherType_type = types.other;
		}
		var ok = !q.readExpr(0);
		q.runPost();
		Console.log(expr, q.readExpr_currType, q.readExpr_currFunc);
		return {
			type: ok ? q.readExpr_currType : null,
			doc:  ok ? q.readExpr_currFunc : null,
		}
	}
}
typedef GmlLinterTypeInfo = {
	type: GmlTypeName,
	doc: GmlFuncDoc,
};

class GmlLinterProblem {
	public var text:String;
	public var pos:AcePos;
	public function new(text:String, pos:AcePos) {
		this.text = text;
		this.pos = pos;
	}
}
