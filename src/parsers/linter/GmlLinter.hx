package parsers.linter;
import ace.AceGmlContextResolver;
import ace.AceGmlTools;
import ace.AceWrap;
import file.kind.gml.KGmlScript;
import gml.GmlFuncDoc;
import gml.GmlImports;
import gml.GmlLocals;
import gml.GmlNamespace;
import gml.file.GmlFileKindTools;
import gml.type.GmlType;
import gml.Project;
import gml.type.GmlTypeCanCastTo;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTools;
import haxe.ds.ReadOnlyArray;
import parsers.linter.GmlLinterInit;
import parsers.linter.GmlLinterReadFlags;
import parsers.linter.misc.GmlLinterPrefsState;
import tools.Aliases;
import tools.Dictionary;
import editors.EditCode;
import parsers.linter.GmlLinterKind;
import gml.GmlVersion;
import ace.extern.*;
import tools.JsTools;
import tools.NativeObject;
import tools.macros.GmlLinterMacros.*;
import gml.GmlAPI;
using gml.type.GmlTypeTools;
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
		if (prefs.suppressAll) return;
		warnings.push(new GmlLinterProblem(text + reader.getStack(), reader.getTopPos()));
	}
	public var errors:Array<GmlLinterProblem> = [];
	function addError(text:String):Void {
		if (prefs.suppressAll) return;
		errors.push(new GmlLinterProblem(text + reader.getStack(), reader.getTopPos()));
	}
	//
	
	var reader:GmlReaderExt;
	
	var editor:EditCode;
	var functionsAreGlobal:Bool;
	var macroCache:Dictionary<GmlCode> = new Dictionary();
	
	/**
	 * Context name - such as current script name or event name.
	 * Note: this can be modified by GmlLinterParser!
	 */
	var context(default, set):String = "";
	public function set_context(ctx:String):String {
		context = ctx;
		if (setLocalVars || setLocalTypes) {
			if ((editor.kind is file.kind.gml.KGmlEvents) && ctx == "properties") {
				// don't re-index properties
			} else {
				if (setLocalVars) editor.locals[ctx] = new GmlLocals(ctx);
				if (setLocalTypes) getImports(true).localTypes = new Dictionary();
			}
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
		var t = AceGmlTools.getSelfTypeForFile(editor.file, context);
		if (t == null && prefs.strictScriptSelf) t = GmlTypeDef.void;
		return t;
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
	
	/** Current preferences state - can be modified via @lint */
	/**
	 * Current preferences state
	 * These are merged from multiple 
	 */
	public var prefs:GmlLinterPrefsState;
	public var options:GmlLinterOptions;
	
	var expr:GmlLinterExpr;
	var funcLiteral:GmlLinterFuncLiteral;
	var binOps:GmlLinterBinOps;
	function initModules() {
		funcLiteral = new GmlLinterFuncLiteral(this);
		expr = new GmlLinterExpr(this);
		binOps = new GmlLinterBinOps(this);
	}
	
	public function new() {
		prefs = {};
		var p1 = Project.current.properties.linterPrefs;
		var p2 = ui.Preferences.current.linterPrefs;
		var p3 = GmlLinterPrefs.defValue;
		NativeObject.forField(p1, k -> {
			Reflect.setField(prefs, k, Reflect.field(p1, k));
		});
		NativeObject.forField(p2, k -> {
			if (Reflect.field(prefs, k) == null) {
				Reflect.setField(prefs, k, Reflect.field(p2, k));
			}
		});
		NativeObject.forField(p3, k -> {
			if (Reflect.field(prefs, k) == null) {
				Reflect.setField(prefs, k, Reflect.field(p3, k));
			}
		});
		prefs.forbidNonIdentCalls = !GmlAPI.stdKind.exists("method");
		
		GmlTypeCanCastTo.allowImplicitNullCast = prefs.implicitNullableCasts;
		GmlTypeCanCastTo.allowImplicitBoolIntCasts = prefs.implicitBoolIntCasts;
		GmlTypeCanCastTo.allowNullToAny = false;
		initModules();
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
	
	/** `+¦ a - b;` -> `+ a - b¦;` */
	function readOps(oldDepth:Int, firstType:GmlType, firstLVal:GmlLinterValue, firstOp:GmlLinterKind, firstVal:String, firstLocalName:String):FoundError {
		return binOps.read(oldDepth, firstType, firstLVal, firstOp, firstVal, firstLocalName);
	}
	
	/**
	 * 
	 * @param	sqb Whether this is a [...args]
	 * @return	number of arguments read, -1 on error
	 */
	function readArgs(oldDepth:Int, sqb:Bool, ?doc:GmlFuncDoc, ?selfType:GmlType, ?fnType:GmlType):Int {
		var newDepth = oldDepth + 1;
		var q = reader;
		seqStart.setTo(reader);
		var seenComma = true;
		var closed = false;
		var argc = 0;
		var argTypes:ReadOnlyArray<GmlType>, argTypeClamp:Int, argTypesLen:Int;
		var templateTypes:Array<GmlType> = null;
		var isFuncValue = false;
		if (doc != null) {
			argTypes = doc.argTypes;
			argTypesLen = argTypes != null ? argTypes.length : 0;
			argTypeClamp = doc.rest && argTypes != null ? argTypesLen - 1 : 0x7fffffff;
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
		} else if (fnType != null && (fnType = fnType.resolve()).getKind() == KFunction) {
			isFuncValue = true;
			argTypes = fnType.unwrapParams();
			argTypesLen = argTypes.length - 1;
			var isRest = argTypesLen > 0 && argTypes[argTypesLen - 1].resolve().getKind() == KRest;
			argTypeClamp = isRest ? argTypesLen - 1 : 0x7fffffff;
		} else {
			argTypes = null;
			argTypesLen = 0;
			argTypeClamp = 0;
		}
		//
		var isMethod = !sqb && (selfType:GmlType).getKind() == KMethodSelf;
		var methodSelf:GmlType = null;
		//
		var hasBufferAutoType:Bool = false;
		var bufferAutoType:GmlType = null;
		var bufferAutoTypeRet = false;
		if (doc != null && argTypes != null && doc.name.contains("buffer_")) {
			for (argType in argTypes) {
				switch (argType) {
					case null:
					case TInst(name, [], KCustom) if (name == "buffer_auto_type"):
						hasBufferAutoType = true;
						break;
					default:
				}
			}
			switch (doc.returnType) {
				case null:
				case TInst(name, [], KCustom) if (name == "buffer_auto_type"):
					hasBufferAutoType = true;
					bufferAutoTypeRet = true;
				default:
			}
		}
		//
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
					if (!seenComma) {
						readExpect("a comma in values list");
						return -1;
					}
					seenComma = false;
					
					if (sqb) { // array literal logic
						if (readExpr(newDepth)) return -1;
						if (argc == 0) {
							itemType = expr.currType;
						} else if (itemType != null) {
							// turn mixed-type array literals into array<any>
							if (!valueCanCastTo(expr.currValue, expr.currType, itemType, null)) {
								itemType = null;
							}
							// tuples require passing the supposed destination type to readExpr.
						}
						argc++;
						continue;
					}
					
					var argType:GmlType;
					var argTypeInd = argc;
					if (argTypes != null) {
						if (argTypeInd > argTypeClamp) argTypeInd = argTypeClamp;
						argType = argTypeInd >= argTypesLen ? null : argTypes[argTypeInd];
					} else argType = null;
					
					// read the next argument:
					if (isMethod && argc == 1) {
						// rewrite `self` for `method()`'s `fn` argument
						var lso = funcLiteral.selfOverride;
						funcLiteral.selfOverride = methodSelf;
						var foundError = readExpr(newDepth);
						funcLiteral.selfOverride = lso;
						if (foundError) return -1;
					} else {
						if (readExpr(newDepth, None, null, argType)) return -1;
					}
					
					if (argTypes != null && expr.currType != null) {
						if (argType != null) {
							if (isFuncValue && argTypeInd == argTypeClamp) argType = argType.unwrapParam();
							if (hasBufferAutoType) {
								switch (argType) {
									case null:
									case TInst(typeName, [], KCustom):
										if (typeName == "buffer_auto_type") {
											argType = bufferAutoType;
										} else if (typeName == "buffer_type") {
											var btmap = parsers.linter.misc.GmlLinterBufferAutoType.map;
											bufferAutoType = btmap[expr.currName];
										}
									default:
								}
							}
							if (!valueCanCastTo(
								expr.currValue, expr.currType,
								argType, templateTypes
							)) {
								var argName:String;
								if (doc != null) {
									argName = JsTools.or(doc.args[argTypeInd], "?");
								} else argName = null;
								addWarning("Can't cast " + expr.currType.toString(templateTypes)
									+ " to " + argType.toString(templateTypes)
									+ ' for ' + argName + "#" + argc
								);
							}
						}
					}
					
					// store `self` type for `method()`:
					if (isMethod && argc == 0) methodSelf = expr.currType;
					
					argc++;
				};
			}
		} // while (q.loop), can continue
		
		if (sqb) {
			readArgs_outType = itemType;
		} else {
			if (doc != null) {
				var retType = doc.returnType;
				if (bufferAutoTypeRet) retType = bufferAutoType;
				readArgs_outType = retType.mapTemplateTypes(templateTypes);
			} else if (isFuncValue) {
				readArgs_outType = argTypes[argTypesLen];
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
			currName = doc.name;
			minArgs = doc.minArgs;
			maxArgs = doc.maxArgs;
			
			// also check for other problems while we are here:
			if (doc.isConstructor) {
				if (!isNew) addWarning('`$currName` is a constructor, but is not used via `new`');
			} else {
				if (isNew) {
					addWarning('`$currName` is not a constructor, but is being used via `new`');
				}
				if (isExpr && prefs.checkHasReturn && doc.hasReturn == false) {
					addWarning('`$currName` does not return anything, the result is unspecified');
				}
			}
		} else {
			// perhaps it's a hidden extension function? we don't add them to extDoc
			minArgs = GmlAPI.extArgc[currName];
			if (minArgs == null) {
				if (prefs.requireFunctions && prefs.forbidNonIdentCalls) {
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
		if (isUserFunc && !prefs.checkScriptArgumentCounts) {
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
	
	@:keep inline function readExpr(oldDepth:Int, flags:GmlLinterReadFlags = None, ?_nk:GmlLinterKind, ?targetType:GmlType):FoundError {
		return expr.read(oldDepth, flags, _nk, targetType);
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
		var typeStr = gml.type.GmlTypeParser.readNameForLinter(this);
		if (typeStr == null) return true;
		readTypeName_typeStr = typeStr;
		return false;
	}
	static var readTypeName_typeStr:String;
	
	function valueCanCastTo(val:GmlLinterValue, valType:GmlType, target:GmlType, tpl:Array<GmlType>):Bool {
		switch (val) {
			case null:
			case VNumber( -1, _):
				var nsName = target.getNamespace();
				if (nsName != null) {
					var ns = GmlAPI.gmlNamespaces[nsName];
					var depth = 0;
					while (ns != null && ++depth < 128) {
						if (ns.minus1able) return true;
						ns = ns.parent;
					}
				}
			default:
		}
		return valType.canCastTo(target, tpl, getImports());
	}
	function checkTypeCast(source:GmlType, target:GmlType, ctx:String, val:GmlLinterValue):Bool {
		if (valueCanCastTo(val, source, target, null)) return true;
		var m = "Can't cast " + source.toString() + " to " + target.toString();
		if (ctx != null) m += " for " + ctx;
		addWarning(m);
		return false;
	}
	function checkTypeCastEq(source:GmlType, target:GmlType, ?ctx:String):Bool {
		var unassignable = GmlTypeDef.parse("uncompareable"); // caches
		if (source.canCastTo(unassignable) && target.canCastTo(unassignable)) {
			if (source.canCastTo(target, null, getImports())) return true;
			addWarning("Can't compare a " + source.toString() + " to a " + target.toString());
		}
		return true;
	}
	function checkTypeCastBoolOp(source:GmlType, val:GmlLinterValue, ctx:String):Bool {
		var wasBoolOp = GmlTypeCanCastTo.isBoolOp;
		GmlTypeCanCastTo.isBoolOp = true;
		var result = checkTypeCast(source, GmlTypeDef.bool, ctx, val);
		GmlTypeCanCastTo.isBoolOp = wasBoolOp;
		return result;
	}
	
	function checkTypeCastOp(
		left:GmlType, leftVal:GmlLinterValue,
		right:GmlType, rightVal:GmlLinterValue,
		op:GmlLinterKind, opv:String
	):GmlType {
		switch (op) {
			case KAdd: {
				if (left.equals(GmlTypeDef.string) || left.equals(GmlTypeDef.number)) {
					return checkTypeCast(right, left, opv, rightVal) ? left : null;
				} else if (right.equals(GmlTypeDef.string) || right.equals(GmlTypeDef.number)) {
					return checkTypeCast(left, right, opv, leftVal) ? right : null;
				}
			};
			case KBoolAnd, KBoolOr, KBoolXor: {
				checkTypeCastBoolOp(left, leftVal, opv);
				checkTypeCastBoolOp(right, rightVal, opv);
				return GmlTypeDef.bool;
			};
			case KEQ, KNE, KSet: {
				checkTypeCastEq(left, right, opv);
				return GmlTypeDef.bool;
			};
			case KLT, KLE, KGT, KGE: {
				checkTypeCast(left, GmlTypeDef.number, opv, leftVal);
				checkTypeCast(right, GmlTypeDef.number, opv, rightVal);
				return GmlTypeDef.bool;
			};
			case KAnd, KOr, KXor, KShl, KShr: {
				checkTypeCast(left, GmlTypeDef.int, opv, leftVal);
				checkTypeCast(right, GmlTypeDef.int, opv, rightVal);
				return GmlTypeDef.int;
			};
			case KIntDiv: {
				checkTypeCast(left, GmlTypeDef.number, opv, leftVal);
				checkTypeCast(right, GmlTypeDef.number, opv, rightVal);
				return GmlTypeDef.int;
			};
			default: {
				checkTypeCast(left, GmlTypeDef.number, opv, leftVal);
				checkTypeCast(right, GmlTypeDef.number, opv, rightVal);
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
				if (prefs.blockScopedCase) discardBlockScopes(newDepth);
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
			if (prefs.requireParentheses && expr.currKind != KParOpen) {
				addWarning("Expression is missing parentheses");
			}
		}
		switch (nk) {
			case KMFuncDecl, KMacro: {};
			case KEnum: rc(readEnum(newDepth));
			case KVar, KConst, KLet, KGlobalVar, KArgs: {
				var isArgs = nk == KArgs;
				var keywordStr = nextVal;
				seqStart.setTo(reader);
				var found = 0;
				var startRow = reader.row;
				while (q.loop) {
					nk = peek();
					// #args-specific: quit on linebreak, allow ?arg:
					if (isArgs && __peekReader.row > startRow) break;
					if (isArgs && nk == KQMark) { skip(); nk = peek(); }
					//
					if (!skipIf(nk == KIdent)) break;
					var varName = nextVal;
					if (mainKind != KGlobalVar) {
						if (mainKind != KVar || prefs.blockScopedVar) {
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
					var argIndex = found++;
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
					} else {
						varType = null;
						varTypeStr = null;
						if (isArgs && currFuncDoc != null && currFuncDoc.argTypes != null) {
							varType = currFuncDoc.argTypes[argIndex];
							varTypeStr = varType != null ? varType.toString() : null;
							if (varType != null && setLocalTypes) {
								getImports(true).localTypes[varName] = varType;
							}
						}
					}
					//
					var typeInfo:String = null;
					if (nk == KSet) { // `name = val`
						skip();
						var setToken = nextVal;
						rc(readExpr(newDepth, None, null, varType));
						var varExprType = expr.currType;
						if (mainKind == KGlobalVar) {
							// not today
						} else if (varType != null) {
							checkTypeCast(varExprType, varType, "variable declaration", expr.currValue);
						} else if (varExprType != null) {
							var apply = setLocalTypes && (
								prefs.specTypeColon && setToken == ":="
							|| switch (mainKind) {
								case KLet: prefs.specTypeLet;
								case KConst: prefs.specTypeConst;
								default: keywordStr == "var" ? prefs.specTypeVar : prefs.specTypeMisc;
							});
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
					if (setLocalVars && mainKind != KGlobalVar) {
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
				if (prefs.requireSemicolons) {
					addWarning("Stray semicolon");
				}
			};
			case KIf: {
				rc(expr.read(newDepth));
				var nullSafety = expr.nullSafety;
				checkParens();
				checkTypeCastBoolOp(expr.currType, expr.currValue, "an if condition");
				skipIf(peek() == KThen);
				if (skipIf(peek() == KSemico)) {
					return readError("You have a semicolon before your then-expression.");
				}
				nullSafety.prepatch(this);
				rc(readStat(newDepth));
				if (skipIf(peek() == KElse)) {
					nullSafety.elsepatch(this);
					rc(readStat(newDepth));
				}
				nullSafety.postpatch(this);
			};
			case KWhile, KRepeat: {
				rc(readExpr(newDepth));
				checkParens();
				switch (nk) {
					case KWhile: checkTypeCastBoolOp(expr.currType, expr.currValue, "a while-loop condition");
					case KRepeat: checkTypeCast(expr.currType, GmlTypeDef.number, "a repeat-loop count", expr.currValue);
					default:
				}
				rc(readLoopStat(newDepth));
			};
			case KWith: {
				var locals = editor.locals[context];
				if (locals != null) locals.hasWith = true;
				rc(readExpr(newDepth));
				var ctxType = expr.currType;
				checkParens();
				var self0z = __selfType_set;
				var self0t = __selfType_type;
				var other0z = __otherType_set;
				var other0t = __otherType_type;
				__otherType_set = true;
				__otherType_type = getSelfType();
				__selfType_set = true;
				__selfType_type = ctxType;
				rc(readLoopStat(newDepth));
				__otherType_set = other0z;
				__otherType_type = other0t;
				__selfType_set = self0z;
				__selfType_type = self0t;
			};
			case KDo: {
				rc(readLoopStat(newDepth));
				switch (next()) {
					case KUntil, KWhile: {
						rc(readExpr(newDepth));
						checkParens();
						checkTypeCastBoolOp(expr.currType, expr.currValue, "an do-loop condition");
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
					checkTypeCastBoolOp(expr.currType, expr.currValue, "an if condition");
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
					case KSemico: skip(); flags.add(NoSemico);
					case KCubClose: flags.add(NoSemico);
					default:
						var retType = currFuncDoc != null ? currFuncDoc.returnType : null;
						rc(readExpr(newDepth, None, null, retType));
						switch (currFuncRetStatus) {
							case NoReturn, WantReturn: currFuncRetStatus = HasReturn;
							case WantNoReturn: 
								addWarning("The function is marked as returning nothing but has a return statement.");
							default:
						}
						if (retType != null && expr.currType != null) {
							checkTypeCast(expr.currType, retType, "return", expr.currValue);
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
				// catch (<name>)
				var hasPar = skipIf(peek() == KParOpen);
				rc(readCheckSkip(KIdent, "an exception name"));
				var varName = nextVal;
				localKinds[varName] = mainKind;
				if (setLocalVars && mainKind != KGlobalVar) {
					var locals = editor.locals[context];
					if (!locals.kind.exists(varName)) {
						locals.add(varName, localVarTokenType, "try-catch");
					}
				}
				if (hasPar) rc(readCheckSkip(KParClose, "a closing `)`"));
				//
				rc(readStat(newDepth)); // catch-block
				if (skipIf(peek() == KFinally)) {
					rc(readStat(newDepth));
				}
			};
			//
			case KLamDef: rc(funcLiteral.read(newDepth, false, true));
			default: {
				rc(readExpr(newDepth, flags.with(AsStat), nk));
			};
		}
		//
		if (skipIf(peek() == KSemico)) {
			// OK!
		} else if (prefs.requireSemicolons && mainKind.needSemico() && !flags.has(NoSemico)) {
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
		functionsAreGlobal = GmlFileKindTools.functionsAreGlobal(editor.kind);
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
		if (code == null) {
			code = synext.SyntaxExtension.postprocForLinterArray(editor, session.getValue(), file.kind.KGml.syntaxExtensions);
		}
		var ohno = q.run(code, editor, gml.Project.current.version);
		t = (Main.window.performance.now() - t);
		//
		if (session.gmlErrorMarkers == null) session.gmlErrorMarkers = [];
		var annotations:Array<AceAnnotation> = [];
		function addMarker(text:String, pos:AcePos, isError:Bool) {
			var line = session.getLine(pos.row);
			var range = new AceRange(0, pos.row, line.length, pos.row);
			var clazz = isError ? "ace_error-line" : "ace_warning-line";
			var marker = new ace.gml.AceGmlWarningMarker(session, pos.row, clazz);
			session.gmlErrorMarkers.push(marker.addTo(session));
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
		Console.log(expr, q.expr.currType, q.expr.currFunc);
		#end
		return {
			type: ok ? q.expr.currType : null,
			doc:  ok ? q.expr.currFunc : null,
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