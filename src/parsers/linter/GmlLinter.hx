package parsers.linter;
import ace.AceGmlContextResolver;
import ace.AceGmlTools;
import ace.AceWrap;
import file.kind.gml.KGmlScript;
import gml.GmlFuncDoc;
import gml.GmlImports;
import gml.GmlLocals;
import gml.GmlNamespace;
import gml.type.GmlType;
import gml.Project;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTools;
import parsers.linter.GmlLinterInit;
import parsers.linter.GmlLinterReadFlags;
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
	
	public static function getOption<T>(fn:GmlLinterPrefs->T):T {
		var lp = Project.current.properties.linterPrefs;
		var r:T = null;
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
	
	var reader:GmlReaderExt;
	
	var editor:EditCode;
	
	/**
	 * Context name - such as current script name or event name.
	 * Note: this can be modified by GmlLinterParser!
	 */
	var context(default, set):String = "";
	public function set_context(ctx:String):String {
		context = ctx;
		if (setLocalVars) {
			editor.locals[ctx] = new GmlLocals(ctx);
			getImports(true).localTypes = new Dictionary();
		}
		return ctx;
	}
	var localVarTokenType:AceTokenType = "local";
	
	function getImports(?force:Bool):GmlImports {
		var imp = editor.imports[context];
		if (imp == null && force) {
			imp = new GmlImports();
			editor.imports[context] = imp;
		}
		return imp;
	}
	
	/**
	 * If the linter is currently walking about a function, this holds that.
	 * For full-file linting this will reflect upon sub-functions, but for
	 * getType it will only have the top-level function info (which is mostly OK).
	 */
	var currFuncDoc:GmlFuncDoc;
	var currFuncRetStatus:GmlLinterReturnStatus = NoReturn;

	var __selfType_set = false;
	var __selfType_type:GmlType = null;
	function getSelfType() {
		if (__selfType_set) return __selfType_type;
		return AceGmlTools.getSelfTypeForFile(editor.file, context);
	}

	
	
	var __otherType_set = false;
	var __otherType_type:GmlType = null;
	function getOtherType() {
		if (__otherType_set) return __otherType_type;
		return AceGmlTools.getOtherType({ session: editor.session, scope: context });
	}
	
	/** depth -> null<variables that should be freed after this depth> */
	var localNamesPerDepth:Array<Array<String>> = [];
	var localKinds:Dictionary<GmlLinterKind> = new Dictionary();
	
	var isProperties:Bool = false;
	var setLocalVars:Bool = false;
	var setLocalTypes:Bool = true;
	
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
	var optSpecTypeVar:Bool;
	var optSpecTypeLet:Bool;
	var optSpecTypeConst:Bool;
	var optSpecTypeMisc:Bool;
	var optRequireFields:Bool;
	
	public function new() {
		optRequireSemico = getOption((q) -> q.requireSemicolons);
		optNoSingleEqu = getOption((q) -> q.noSingleEquals);
		optRequireParentheses = getOption((q) -> q.requireParentheses);
		optBlockScopedVar = getOption((q) -> q.blockScopedVar);
		optBlockScopedCase = getOption((q) -> q.blockScopedCase);
		optRequireFunctions = getOption((q) -> q.requireFunctions);
		optCheckHasReturn = getOption((q) -> q.checkHasReturn);
		optCheckScriptArgumentCounts = getOption((q) -> q.checkScriptArgumentCounts);
		optSpecTypeVar = getOption((q) -> q.specTypeVar);
		optSpecTypeLet = getOption((q) -> q.specTypeLet);
		optSpecTypeConst = getOption((q) -> q.specTypeConst);
		optSpecTypeMisc = getOption((q) -> q.specTypeMisc);
		optRequireFields = getOption((q) -> q.requireFields);
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
		keywords = GmlLinterInit.keywords(version.config);
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
	function readOps(oldDepth:Int, firstType:GmlType, firstOp:GmlLinterKind, firstVal:String):FoundError {
		var newDepth = oldDepth + 1;
		var q = reader;
		var types = [firstType];
		var ops = [firstOp];
		var vals = [firstVal];
		while (q.loop) {
			rc(readExpr(newDepth, NoOps));
			types.push(readExpr_currType);
			var nk = peek();
			if (nk.isBinOp() || nk == KSet) {
				skip();
				ops.push(nk);
				vals.push(nextVal);
			} else break;
		}
		//
		var pmin = GmlLinterKind.getMaxBinPriority();
		var pmax = 0;
		for (op in ops) {
			var pc = op.getBinOpPriority();
			if (pc < pmin) pmin = pc;
			if (pc > pmax) pmax = pc;
		}
		//
		while (pmin <= pmax) {
			var i = 0;
			while (i < ops.length) {
				var op = ops[i];
				if (op.getBinOpPriority() == pmin) {
					var t1 = types[i];
					var t2 = types[i + 1];
					var tr:GmlType = null;
					types[i] = checkTypeCastOp(t1, t2, ops[i], vals[i]);
					types.splice(i + 1, 1);
					vals.splice(i, 1);
					ops.splice(i, 1);
				} else i += 1;
			}
			pmin += 1;
		}
		//
		readExpr_currType = types[0];
		return false;
	}
	
	/**
	 * 
	 * @param	sqb Whether this is a [...args]
	 * @return	number of arguments read, -1 on error
	 */
	function readArgs(oldDepth:Int, sqb:Bool, ?doc:GmlFuncDoc, ?selfType:GmlType):Int {
		var newDepth = oldDepth + 1;
		var q = reader;
		seqStart.setTo(reader);
		var seenComma = true;
		var closed = false;
		var argc = 0;
		var argTypes:Array<GmlType>, argTypeLast:Int;
		var templateTypes:Array<GmlType> = null;
		if (doc != null) {
			argTypes = doc.argTypes;
			argTypeLast = doc.rest && argTypes != null ? argTypes.length - 1 : 0x7fffffff;
			if (doc.templateItems != null) {
				templateTypes = NativeArray.create(doc.templateItems.length);
			}
			if (doc.templateSelf != null) {
				if (!GmlTypeTools.canCastTo(selfType, doc.templateSelf, templateTypes, getImports())) {
					addWarning("Can't cast " + selfType.toString(templateTypes)
						+ " to " + doc.templateSelf.toString(templateTypes)
						+ ' for ' + doc.name + "#self"
					);
				}
			}
		} else {
			argTypes = null;
			argTypeLast = 0;
		}
		var itemType:GmlType = null;
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
						if (sqb) {
							if (argc == 0) {
								itemType = readExpr_currType;
							} else if (itemType != null) {
								// turn mixed-type array literals into array<any>
								if (!readExpr_currType.canCastTo(itemType)) itemType = null;
								// tuples require passing the supposed destination type to readExpr.
							}
						} else if (argTypes != null && readExpr_currType != null) {
							var argTypeInd = argc > argTypeLast ? argTypeLast : argc;
							var argType = argTypes[argTypeInd];
							if (argType != null && !readExpr_currType.canCastTo(argType, templateTypes, getImports())) {
								var argName = JsTools.or(doc.args[argTypeInd], "?");
								addWarning("Can't cast " + readExpr_currType.toString(templateTypes)
									+ " to " + argType.toString(templateTypes)
									+ ' for ' + argName + "#" + argc
								);
							}
						}
						argc++;
					} else {
						readExpect("a comma in values list");
						return -1;
					}
				};
			}
		}
		if (sqb) {
			readArgs_outType = itemType;
		} else {
			if (doc != null) {
				readArgs_outType = doc.returnType.mapTemplateTypes(templateTypes);
			} else readArgs_outType = null;
		}
		if (!closed) {
			readSeqStartError("Unclosed " + (sqb ? "[]" : "()"));
			return -1;
		} else return argc;
	}
	static var readArgs_outType:GmlType;
	
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
	
	/**
	 * Indicates whatever it is that readExpr just parsed.
	 * It is the right-most top-level expression, so
	 * a.b -> KField
	 * (a.b) -> KParOpen
	 * (a.b).c -> KField
	 */
	var readExpr_currKind:GmlLinterKind;
	
	/** If readExpr just parsed something starting with an identifier, this holds that.  */
	var readExpr_currName:GmlName;
	
	/** Resulting type of last parsed expression. Often is null. */
	var readExpr_currType:GmlType;
	
	/** For `<expr>.field`, indicates type of `<expr>` */
	var readExpr_selfType:GmlType;
	
	/** If the resulting expression is a function */
	var readExpr_currFunc:GmlFuncDoc;
	
	/** If processed expression evaluates to a literal, this holds that */
	var readExpr_currValue:GmlLinterValue;
	
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
		var selfType:GmlType = null;
		var currType:GmlType = null;
		var currFunc:GmlFuncDoc = null;
		var currValue:GmlLinterValue = null;
		//
		inline function checkConst():Void {
			readExpr_checkConst(currName, currKind);
		}

		//
		switch (nk) {
			case KNumber: {
				currType = GmlTypeDef.number;
				var nv = nextVal;
				currValue = VNumber(Std.parseFloat(nv), nv);
			};
			case KString: {
				currType = GmlTypeDef.string;
				var nv = nextVal;
				currValue = VString(null, nv); // todo: probably parse string?
			};
			case KUndefined: {
				currType = GmlTypeDef.undefined;
				currValue = VUndefined;
			};
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
				do {
					switch (currName) {
						case "self":
							currType = getSelfType();
							currFunc = currType.getSelfCallDoc(getImports());
							break;
						case "other":
							currType = getOtherType();
							currFunc = currType.getSelfCallDoc(getImports());
							break;
						case "global":
							currType = GmlTypeDef.global;
							break;
						case "true", "false":
							currType = GmlTypeDef.bool;
							break;
					}
					
					var imp:GmlImports = getImports();
					var locals = editor.locals[context];
					if (imp != null && locals != null && locals.kind.exists(currName)) {
						currType = imp.localTypes[currName];
						currFunc = currType.getSelfCallDoc(imp);
						break;
					}
					
					var lam = editor.lambdas[context];
					if (lam != null && lam.kind.exists(currName)) {
						currFunc = lam.docs[currName];
						break;
					}
					
					var kind = GmlAPI.gmlKind[currName];
					if (kind != null) {
						if (kind.startsWith("asset.")) {
							kind = kind.substring(6);
							if (kind == "object") {
								currType = GmlTypeDef.object(currName);
							} else if (kind == "script") {
								currFunc = GmlAPI.gmlDoc[currName];
								currType = JsTools.nca(currFunc, currFunc.getFunctionType());
							} else {
								currType = GmlTypeDef.simple(kind);
							}
							break;
						} else if (kind == "enum") {
							currType = GmlTypeDef.type(currName);
						}
					}
					if (AceGmlTools.findNamespace(currName, imp, function(ns:GmlNamespace) {
						if (ns.noTypeRef) return false;
						currType = GmlTypeDef.type(currName);
						currFunc = JsTools.or(ns.docStaticMap[""], AceGmlTools.findGlobalFuncDoc(currName));
						return true;
					})) break;
					if (kind != null) {
						currType = GmlAPI.gmlTypes[currName];
						break;
					}
					
					if (GmlAPI.extKind.exists(currName)) {
						currFunc = GmlAPI.extDoc[currName];
						if (currType == null && currFunc != null) {
							currType = currFunc.getFunctionType();
						}
						break;
					}
					
					if (GmlAPI.stdKind.exists(currName)) {
						currFunc = GmlAPI.stdDoc[currName];
						currType = GmlAPI.stdTypes[currName];
						if (currType == null && currFunc != null) {
							currType = currFunc.getFunctionType();
						}
						break;
					}
					
					var t = getSelfType();
					var tn = t.getNamespace();
					if (tn != null) {
						var wantWarn = false;
						var found = AceGmlTools.findNamespace(tn, imp, function(ns:GmlNamespace) {
							wantWarn = true;
							if (ns.getInstKind(currName) != null) {
								currType = ns.getInstType(currName);
								currFunc = ns.getInstDoc(currName);
								return true;
							} else return false;
						});
						if (!found && wantWarn && optRequireFields) addWarning('Variable $currName is not part of $tn');
					}
				} while (false);
			};
			case KParOpen: {
				rc(readExpr(newDepth));
				if (next() != KParClose) return readExpect("a `)`");
				currType = readExpr_currType;
				currFunc = readExpr_currFunc;
			};
			case KNew: {
				rc(readExpr(newDepth, IsNew));
				currType = JsTools.or(readExpr_currType, GmlTypeDef.simple(readExpr_currName));
				currFunc = currType.getSelfCallDoc(getImports());
			};
			case KCast: {
				rc(readExpr(newDepth, GmlLinterReadFlags.NoOps.with(IsCast)));
				if (readExpr_currKind == KAs) {
					currType = readExpr_currType;
				} else currType = null;
				currFunc = null;
			};
			case KNot, KBitNot: {
				rc(readExpr(newDepth));
				if (nk == KNot) {
					checkTypeCast(readExpr_currType, GmlTypeDef.bool, "!");
					currType = GmlTypeDef.bool;
				} else {
					checkTypeCast(readExpr_currType, GmlTypeDef.int, "~");
					currType = GmlTypeDef.int;
				}
			};
			case KInc, KDec: {
				rc(readExpr(newDepth, HasPrefix));
				checkTypeCast(readExpr_currType, GmlTypeDef.number, nk == KInc ? "++" : "--");
				currType = GmlTypeDef.number;
			};
			case KSqbOpen: {
				var found = readArgs(newDepth, true);
				rc(found < 0);
				currType = found > 0 ? GmlTypeDef.array(readArgs_outType) : GmlTypeDef.anyArray;
			};
			case KLambda, KFunction:
				rc(readLambda(newDepth, nk == KFunction, isStat()));
				currFunc = readLambda_doc;
				currType = currFunc.getFunctionType();
			case KCubOpen: { // { fd1: v1, fd2: v2 }
				var anon = new GmlTypeAnon();
				var anonFields = anon.fields;
				if (skipIf(peek() == KCubClose)) {
					// empty!
				} else while (q.loop) {
					var key:String;
					switch (next()) {
						case KIdent: key = nextVal;
						case KString:
							try {
								key = haxe.Json.parse(nextVal);
							} catch (x:Dynamic) {
								key = null;
								addWarning("Invalid string for key name");
							}
						case KCubClose: break;
						default: return readExpect("a field name");
					}
					rc(readCheckSkip(KColon, "a `:` between key-value pair in {}"));
					rc(readExpr(newDepth));
					if (key != null) {
						anonFields[key] = new GmlTypeAnonField(readExpr_currType, readExpr_currFunc);
					}
					switch (peek()) {
						case KCubClose: skip(); break;
						case KComma: skip();
						default: return readExpect("a `,` or a `}` after a key-value pair in {}");
					}
				}
				currType = GmlType.TAnon(anon);
			};
			default: {
				if (nk.isUnOp()) { // +v or -v
					rc(readExpr(newDepth));
					checkTypeCast(readExpr_currType, GmlTypeDef.number, nk == KAdd ? "+" : "-");
					currType = GmlTypeDef.number;
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
						checkTypeCast(readExpr_currType, currType);
						currType = null;
					} else {
						if (hasFlag(NoOps)) break;
						if (optNoSingleEqu) {
							addWarning("Using single `=` as a comparison operator");
						}
						skip();
						rc(readOps(newDepth, currType, nk, "="));
						flags.add(NoSfx);
						currType = readExpr_currType;
					}
				};
				case KParOpen: { // fn(...)
					if (optForbidNonIdentCalls && !currKind.canCall()) {
						return readError('Expression ${currKind.getName()} is not callable');
					}
					if (hasFlag(NoSfx)) return readError("Can't call this");
					skip();
					var argc = readArgs(newDepth, false, currFunc, selfType);
					rc(argc < 0);
					if (currFunc != null) {
						checkCallArgs(currFunc, currName, argc, !isStat(), hasFlag(IsNew));
					}
					statKind = currKind = KCall;
					currType = readArgs_outType;
					currFunc = currType.getSelfCallDoc(getImports());
				};
				case KInc, KDec: { // x++, x--
					if (hasFlag(NoSfx)) break;
					if (!currKind.canPostfix()) break;
					checkConst();
					skip();
					statKind = currKind = nk;
					currType = GmlTypeDef.number;
				};
				case KDot, KNullDot: { // x.y
					skip();
					rc(readCheckSkip(KIdent, "field name after `.`"));
					var field = nextVal;
					
					// extract `Type` from `Type?` when doing `v?.field`
					if (nk == KNullDot && currType.isNullable()) currType = currType.unwrapParam();
					
					currKind = nk == KDot ? KField : KNullField;
					var isStatic = currType.isType();
					var nsType = isStatic ? currType.unwrapParam() : currType;
					var ctn = nsType.getNamespace();
					selfType = currType;
					if (ctn != null) {
						var wantWarn = false;
						var found = AceGmlTools.findNamespace(ctn, getImports(), function(ns) {
							wantWarn = true;
							if (isStatic) {
								currType = ns.staticTypes[field];
								currFunc = ns.docStaticMap[field];
								return ns.staticKind.exists(field);
							} else {
								currType = ns.getInstType(field);
								currFunc = ns.getInstDoc(field);
								return ns.getInstKind(field) != null;
							}
						});
						
						if (found) {
							if (currType != null) switch (selfType) {
								case TInst(_, sp, _) if (sp.length > 0): {
									currType = currType.mapTemplateTypes(sp);
								};
								default:
							}
						} else {
							var en = GmlAPI.gmlEnums[ctn];
							if (en != null) {
								wantWarn = true;
								if (en.items.exists(field)) {
									// TODO: come up with some method of indicating that enum
									// is typed as itself and may not cast to integers
									currType = GmlTypeDef.int;
									found = true;
								} else currType = GmlTypeDef.forbidden;
							} else currType = null;
							currFunc = null;
						}
						if (!found && wantWarn && optRequireFields) addWarning('Variable $field is not part of $ctn');
					} else {
						currType = selfType.getKind() == KGlobal ? GmlAPI.gmlGlobalTypes[field] : null;
						currFunc = null;
					}
				};
				case KSqbOpen, KNullSqb: { // x[i], x[?i], etc.
					skip();
					var isNull = nk == KNullSqb;
					
					// extract `Type` from `Type?` when doing `v?[indexer]`
					if (isNull && currType.isNullable()) currType = currType.unwrapParam();
					
					var isArray = false;
					var isLiteral = false;
					var arrayType1 = null;
					var arrayType2 = null;
					switch (peek()) {
						case KQMark: { // map[?k]
							skip();
							rc(readExpr(newDepth));
							if (checkTypeCast(currType, GmlTypeDef.ds_map)) {
								checkTypeCast(readExpr_currType, currType.unwrapParam(0), "map key");
								currType = currType.unwrapParam(1);
							} else currType = null;
						};
						case KOr: { // list[|i]
							skip();
							
							rc(readExpr(newDepth));
							checkTypeCast(readExpr_currType, GmlTypeDef.number, "list index");
							
							if (checkTypeCast(currType, GmlTypeDef.ds_list)) {
								currType = currType.unwrapParam(0);
							} else currType = null;
						};
						case KDollar: { // struct[$k]
							skip();
							
							rc(readExpr(newDepth));
							checkTypeCast(readExpr_currType, GmlTypeDef.string, "struct key");
							
							if (true) { // todo: validate that object is struct-like
								currType = currType.unwrapParam(0);
							} else currType = null;
						};
						case KHash: { // grid[#x, y]
							skip();
							
							rc(readExpr(newDepth));
							checkTypeCast(readExpr_currType, GmlTypeDef.number, "grid X");
							
							rc(readCheckSkip(KComma, "a comma before second index"));
							rc(readExpr(newDepth));
							checkTypeCast(readExpr_currType, GmlTypeDef.number, "grid Y");
							
							if (checkTypeCast(currType, GmlTypeDef.ds_grid)) {
								currType = currType.unwrapParam(0);
							} else currType = null;
						};
						case KAtSign: { // array[@i] or array[@i, k]
							skip();
							
							rc(readExpr(newDepth));
							checkTypeCast(readExpr_currType, GmlTypeDef.number, "array index");
							
							if (skipIf(peek() == KComma)) {
								rc(readExpr(newDepth));
								checkTypeCast(readExpr_currType, GmlTypeDef.number, "second array index");
							}
							
							if (checkTypeCast(currType, GmlTypeDef.anyArray)) {
								currType = currType.unwrapParam(0);
							} else currType = null;
						};
						default: { // array[i] or array[i, k]
							isArray = true;
							
							rc(readExpr(newDepth));
							arrayType1 = readExpr_currType;
							
							if (skipIf(peek() == KComma)) {
								rc(readExpr(newDepth));
								arrayType2 = readExpr_currType;
							}
							if (isNull && skipIf(peek() == KComma)) { // whoops, a?[b,c,d]
								readArgs(newDepth, true);
								isLiteral = true;
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
						if (isArray) {
							if (arrayType1 != null) checkTypeCast(arrayType1, GmlTypeDef.number);
							if (arrayType2 != null) checkTypeCast(arrayType2, GmlTypeDef.number);
							if (checkTypeCast(currType, GmlTypeDef.anyArray)) {
								currType = currType.unwrapParam(0);
							} else currType = null;
						}
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
				case KAs: { // <expr> as <type>
					if (hasFlag(NoSfx)) break;
					skip();
					var tnp = q.pos;
					rc(readTypeName());
					var asType = GmlTypeDef.parse(readTypeName_typeStr);
					if (!hasFlag(IsCast)) {
						var ex = GmlTypeTools.canCastTo_explicit;
						GmlTypeTools.canCastTo_explicit = true;
						checkTypeCast(currType, asType, "as");
						GmlTypeTools.canCastTo_explicit = ex;
					}
					currType = asType;
					currFunc = null;
					currKind = KAs;
				};
				case KQMark: { // x ? y : z
					if (hasFlag(NoOps)) break;
					checkTypeCast(currType, GmlTypeDef.bool, "ternary condition");
					skip();
					rc(readExpr(newDepth));
					currType = readExpr_currType;
					rc(readCheckSkip(KColon, "a colon in a ternary operator"));
					rc(readExpr(newDepth));
					if (currType != null) {
						checkTypeCast(readExpr_currType, currType, "ternary else-value");
					} else currType = readExpr_currType;
					currKind = KQMark;
				};
				case KNullCoalesce: { // x ?? y
					if (hasFlag(NoOps)) break;
					skip();
					rc(readExpr(newDepth));
					if (currType.isNullable()) currType = currType.unwrapParam();
					checkTypeCast(readExpr_currType, currType, "?? operator value");
					currKind = KNullCoalesce;
				};
				default: {
					if (nk.isSetOp()) {
						if (!isStat()) return readError("Can't use " + nextDump() + " here.");
						checkConst();
						skip();
						var opv = currType != null ? nextVal : null;
						currKind = statKind = KSet;
						rc(readExpr(newDepth));
						if (currType != null) {
							var opk = opv == "+=" ? KAdd : KSub;
							checkTypeCastOp(currType, readExpr_currType, opk, opv);
						}
						currType = null;
						flags.add(NoSfx);
					}
					else if (nk.isBinOp()) {
						if (hasFlag(NoOps)) break;
						skip();
						rc(readOps(newDepth, currType, nk, nextVal));
						currType = readExpr_currType;
						flags.add(NoSfx);
					}
					else break;
				};
			}
			if (nk != KDot && nk != KNullDot) selfType = null;
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
		readExpr_selfType = selfType;
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
	
	function readTypeName():FoundError {
		// also see: GmlTypeParser, GmlReader.skipType
		var start = reader.pos;
		var startDepth = reader.depth;
		var typeStr:String;
		switch (next()) {
			case KParOpen:
				seqStart.setTo(reader);
				rc(readTypeName());
				if (next() != KParClose) return readSeqStartError("Unclosed type ()");
				typeStr = '($readTypeName_typeStr)';
			case KIdent, KUndefined:
				typeStr = nextVal;
				if (skipIf(peek() == KLT)) {
					var depth = 1;
					typeStr += "<";
					seqStart.setTo(reader);
					while (reader.loop) {
						switch (next()) {
							case KLT:
								typeStr += "<";
								depth += 1;
							case KGT:
								typeStr += ">";
								depth -= 1;
								if (depth <= 0) break;
							default:
								typeStr += nextVal;
						}
					}
					if (depth > 0) return readSeqStartError("Unclosed type parameters");
				}
			default: return readExpect("a type name");
		}
		while (reader.loop) {
			switch (peek()) {
				case KSqbOpen:
					skip();
					readCheckSkip(KSqbClose, "a closing `]`");
					typeStr += "[]";
				case KQMark:
					skip();
					typeStr += "?";
				case KOr:
					skip();
					rc(readTypeName());
					typeStr += "|" + readTypeName_typeStr;
				default: break;
			}
		}
		// todo: maybe just form the type name here too
		readTypeName_typeStr = typeStr;
		return false;
	}
	static var readTypeName_typeStr:String;
	
	function checkTypeCast(source:GmlType, target:GmlType, ?ctx:String):Bool {
		if (source.canCastTo(target, null, getImports())) return true;
		var m = "Can't cast " + source.toString() + " to " + target.toString();
		if (ctx != null) m += " for " + ctx;
		addWarning(m);
		return false;
	}
	
	function checkTypeCastOp(left:GmlType, right:GmlType, op:GmlLinterKind, opv:String):GmlType {
		switch (op) {
			case KAdd: {
				if (left.equals(GmlTypeDef.string) || left.equals(GmlTypeDef.number)) {
					return checkTypeCast(right, left, opv) ? left : null;
				} else if (right.equals(GmlTypeDef.string) || right.equals(GmlTypeDef.number)) {
					return checkTypeCast(left, right, opv) ? right : null;
				}
			};
			case KBoolAnd, KBoolOr, KBoolXor: {
				checkTypeCast(left, GmlTypeDef.bool, opv);
				checkTypeCast(right, GmlTypeDef.bool, opv);
				return GmlTypeDef.bool;
			};
			case KEQ, KNE, KSet: {
				// GML lets you compare anything to anything and that's okay
				return GmlTypeDef.bool;
			};
			case KLT, KLE, KGT, KGE: {
				checkTypeCast(left, GmlTypeDef.number, opv);
				checkTypeCast(right, GmlTypeDef.number, opv);
				return GmlTypeDef.bool;
			};
			case KAnd, KOr, KXor, KShl, KShr: {
				checkTypeCast(left, GmlTypeDef.int, opv);
				checkTypeCast(right, GmlTypeDef.int, opv);
				return GmlTypeDef.int;
			};
			case KIntDiv: {
				checkTypeCast(left, GmlTypeDef.number, opv);
				checkTypeCast(right, GmlTypeDef.number, opv);
				return GmlTypeDef.int;
			};
			default: {
				checkTypeCast(left, GmlTypeDef.number, opv);
				checkTypeCast(right, GmlTypeDef.number, opv);
				return GmlTypeDef.number;
			};
		}
		return null;
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
	function readLambda(oldDepth:Int, isFunc:Bool, isStat:Bool):FoundError {
		var name = "function";
		var isTopLevel = isFunc && isStat && oldDepth == 2;
		if (peek() == KIdent) {
			skip();
			name = nextVal;
			if (isTopLevel) context = name;
		}
		var doc = new GmlFuncDoc(name, "(", ")", [], false);
		var nextLocalType = isTopLevel ? "local" : "sublocal";
		if (skipIf(peek() == KParOpen)) { // (...args)
			var depth = 1;
			var awaitArgName = true;
			while (reader.loop) {
				switch (next()) {
					case KParOpen: depth++;
					case KParClose: if (--depth <= 0) break;
					case KIdent: {
						if (awaitArgName) {
							var argName = nextVal;
							awaitArgName = false;
							doc.args.push(nextVal);
							var imp = getImports(setLocalTypes);
							var argTypeStr = null;
							if (skipIf(peek() == KColon)) {
								rc(readTypeName());
								argTypeStr = readTypeName_typeStr;
								var t = GmlTypeDef.parse(argTypeStr);
								if (setLocalTypes) imp.localTypes[argName] = t;
								if (doc.argTypes == null) {
									doc.argTypes = NativeArray.create(doc.args.length - 1);
								}
								doc.argTypes.push(t);
							} else {
								if (setLocalTypes) imp.localTypes[argName] = null;
								if (doc.argTypes != null) doc.argTypes.push(null);
							}
							if (setLocalVars) editor.locals[context].add(argName, nextLocalType,
								JsTools.nca(argTypeStr, "type " + argTypeStr)
							);
						}
					};
					case KComma: if (depth == 1) awaitArgName = true;
					default:
				}
			}
		} else if (isFunc) return readExpect("function literal arguments");
		//
		var nextFuncRetStatus = GmlLinterReturnStatus.NoReturn;
		if (skipIf(peek() == KArrow)) { // `->returnType`
			rc(readTypeName());
			doc.returnTypeString = readTypeName_typeStr;
			nextFuncRetStatus = (doc.returnType.getKind() == KVoid ? WantNoReturn : WantReturn);
		}
		if (isFunc && skipIf(peek() == KColon)) { // : <parent>(...super args)
			readCheckSkip(KIdent, "a parent type name");
			readCheckSkip(KParOpen, "opening bracket");
			rc(readArgs(oldDepth + 1, false) < 0);
		}
		if (isFunc) { // `function() constructor`?
			skipIf(peek() == KIdent && nextVal == "constructor");
		}
		//
		var oldLocalNames = localNamesPerDepth;
		var oldLocalKinds = localKinds;
		var oldFuncDoc = currFuncDoc;
		var oldFuncRetStatus = currFuncRetStatus;
		var oldLocalTokenType = localVarTokenType;
		
		localNamesPerDepth = [];
		localKinds = new Dictionary();
		currFuncDoc = doc;
		currFuncRetStatus = nextFuncRetStatus;
		localVarTokenType = nextLocalType;
		
		rc(readStat(0));
		
		switch (currFuncRetStatus) {
			case HasReturn:
				if (nextFuncRetStatus == NoReturn) doc.returnTypeString = "";
			case WantReturn:
				addWarning("The function is marked as having a return but does not return anything.");
			case NoReturn:
				doc.hasReturn = false;
			default:
		}
		
		localNamesPerDepth = oldLocalNames;
		localKinds = oldLocalKinds;
		currFuncDoc = oldFuncDoc;
		currFuncRetStatus = oldFuncRetStatus;
		localVarTokenType = oldLocalTokenType;
		
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
				var keywordStr = nextVal;
				seqStart.setTo(reader);
				var found = 0;
				while (q.loop) {
					nk = peek();
					//if (z && nk == KQMark) { skip(); nk = peek(); }
					if (!skipIf(nk == KIdent)) break;
					var varName = nextVal;
					if (mainKind != KGlobalVar) {
						if (mainKind != KVar || optBlockScopedVar) {
							var lk = localKinds[varName];
							if (lk != null && lk != KGhostVar) {
								addWarning('Redefinition of a variable `$varName`');
							} else {
								var arr = localNamesPerDepth[oldDepth];
								if (arr == null) {
									arr = [];
									localNamesPerDepth[oldDepth] = arr;
								}
								arr.push(varName);
							}
						}
						localKinds[varName] = mainKind;
					}
					found++;
					//
					nk = peek();
					var varType:GmlType, varTypeStr:String;
					if (nk == KColon) { // `name:type`
						skip();
						var varTypeStart = q.pos;
						rc(readTypeName());
						varTypeStr = readTypeName_typeStr;
						varType = GmlTypeDef.parse(varTypeStr);
						if (setLocalTypes) getImports(true).localTypes[varName] = varType;
						nk = peek();
					} else { varType = null; varTypeStr = null; }
					//
					var typeInfo:String = null;
					if (nk == KSet) { // `name = val`
						skip();
						rc(readExpr(newDepth));
						var varExprType = readExpr_currType;
						if (varType != null) {
							checkTypeCast(varExprType, varType);
						} else if (varExprType != null) {
							var apply = setLocalTypes && switch (mainKind) {
								case KLet: optSpecTypeLet;
								case KConst: optSpecTypeConst;
								default: keywordStr == "var" ? optSpecTypeVar : optSpecTypeMisc;
							}
							if (apply) {
								var imp = getImports(true);
								var lastVarType = imp.localTypes[varName];
								if (lastVarType == null) {
									if (setLocalVars) typeInfo = "type " + varExprType.toString() + " (auto)";
									imp.localTypes[varName] = varExprType;
								} else if (!varExprType.equals(lastVarType)) {
									addWarning('Implicit redefinition of type for local variable $varName from '
										+ lastVarType.toString() + " to " + varExprType.toString());
								}
							}
						}
					}
					if (setLocalVars) {
						if (typeInfo == null && varTypeStr != null) {
							typeInfo = "type " + varTypeStr;
						}
						var locals = editor.locals[context];
						if (locals.kind.exists(varName)) {
							if (typeInfo != null) {
								var comp = locals.comp.findFirst((cc) -> cc.name == varName);
								if (comp != null) comp.doc = typeInfo;
							}
						} else locals.add(varName, localVarTokenType, typeInfo);
					}
					//
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
				checkTypeCast(readExpr_currType, GmlTypeDef.bool, "an if condition");
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
				switch (nk) {
					case KWhile: checkTypeCast(readExpr_currType, GmlTypeDef.bool, "a while-loop condition");
					case KRepeat: checkTypeCast(readExpr_currType, GmlTypeDef.number, "a repeat-loop count");
					default:
				}
				rc(readLoopStat(newDepth));
			};
			case KDo: {
				rc(readLoopStat(newDepth));
				switch (next()) {
					case KUntil, KWhile: {
						rc(readExpr(newDepth));
						checkParens();
						checkTypeCast(readExpr_currType, GmlTypeDef.bool, "an do-loop condition");
					};
					default: return readExpect("an `until` or `while` for a do-loop");
				}
			};
			case KFor: {
				if (next() != KParOpen) return readExpect("a `(` to open a for-loop");
				if (!skipIf(peek() == KSemico)) { // init
					rc(readStat(newDepth));
				}
				if (!skipIf(peek() == KSemico)) { // condition
					rc(readExpr(newDepth));
					checkTypeCast(readExpr_currType, GmlTypeDef.bool, "an if condition");
					skipIf(peek() == KSemico);
				}
				if (!skipIf(peek() == KParClose)) { // post
					rc(readLoopStat(newDepth, NoSemico));
					if (next() != KParClose) return readExpect("a `)` to close a for-loop");
				}
				rc(readLoopStat(newDepth));
			};
			case KExit: {};
			case KReturn: {
				switch (peek()) {
					case KSemico, KCubClose: skip(); flags.add(NoSemico);
					default:
						rc(readExpr(newDepth));
						switch (currFuncRetStatus) {
							case NoReturn, WantReturn: currFuncRetStatus = HasReturn;
							case WantNoReturn: 
								addWarning("The function is marked as returning nothing but has a return statement.");
							default:
						}
						if (currFuncDoc != null && readExpr_currType != null) {
							checkTypeCast(readExpr_currType, currFuncDoc.returnType, "return");
						}
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
			case KLamDef: rc(readLambda(newDepth, false, true));
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
	
	public function runPre(source:GmlCode, editor:EditCode, version:GmlVersion, context:String = ""):Void {
		this.version = version;
		this.editor = editor;
		this.context = context;
		if (context != "") {
			currFuncDoc = GmlAPI.gmlDoc[context];
		} else if (Std.is(editor.kind, KGmlScript) && !Project.current.isGMS23) {
			currFuncDoc = GmlAPI.gmlDoc[editor.file.name];
		} else currFuncDoc = null;
		initKeywords();
		var q = reader = new GmlReaderExt(source.trimRight());
		q.name = editor.file.name;
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
	
	
	public static function runFor(editor:EditCode, ?opt:GmlLinterOptions):FoundError {
		var q = new GmlLinter();
		q.setLocalVars = JsTools.ncf(opt.setLocals, false);
		var session = JsTools.ncf(opt.session, editor.session);
		if (session.gmlErrorMarkers != null) {
			for (mk in session.gmlErrorMarkers) session.removeMarker(mk);
			session.gmlErrorMarkers.clear();
			session.clearAnnotations();
		}
		var t = Main.window.performance.now();
		var code = JsTools.ncf(opt.code);
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
		if (JsTools.ncf(opt.updateStatusBar, true)) {
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
			var aceEditor = JsTools.ncf(opt.editor, Main.aceEditor);
			Main.window.setTimeout(function() {
				var statusBar = aceEditor.statusBar;
				statusBar.ignoreUntil = Main.window.performance.now() + statusBar.delayTime + 50;
				statusBar.setText(msg);
			}, 50);
		}
		session.setAnnotations(annotations);
		return ohno;
	}
	
	public static function getType(expr:String, editor:EditCode, context:String, pos:AcePos):GmlLinterTypeInfo {
		var q = new GmlLinter();
		q.setLocalTypes = false;
		q.runPre(expr, editor, Project.current.version, context);
		if (pos != null) {
			var types = AceGmlContextResolver.run(editor.session, pos);
			#if debug
			Console.log(types);
			#end
			q.__selfType_set = true;
			q.__selfType_type = types.self;
			q.__otherType_set = true;
			q.__otherType_type = types.other;
		}
		var ok = !q.readExpr(0);
		q.runPost();
		#if debug
		Console.log(expr, q.readExpr_currType, q.readExpr_currFunc);
		#end
		return {
			type: ok ? q.readExpr_currType : null,
			doc:  ok ? q.readExpr_currFunc : null,
		}
	}
}
typedef GmlLinterOptions = {
	?code:GmlCode,
	?editor:AceWrap,
	?session:AceSession,
	?setLocals:Bool,
	?updateStatusBar:Bool,
}
typedef GmlLinterTypeInfo = {
	type: GmlType,
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

enum GmlLinterValue {
	VUndefined;
	VNumber(n:Float, gml:String);
	VString(s:String, gml:String);
}
enum abstract GmlLinterReturnStatus(Int) {
	var NoReturn;
	var HasReturn;
	var WantReturn;
	var WantNoReturn;
}