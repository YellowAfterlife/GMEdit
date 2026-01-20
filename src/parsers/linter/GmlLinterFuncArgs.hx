package parsers.linter;
import gml.GmlFuncDoc;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTools;
import haxe.ds.ReadOnlyArray;
import parsers.linter.GmlLinter.GmlLinterValue;
import synext.GmlExtCoroutines;
import tools.Aliases;
import tools.JsTools;
import tools.NativeArray;
import tools.macros.GmlLinterMacros.*;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
@:access(parsers.linter.GmlLinter)
class GmlLinterFuncArgs extends GmlLinterHelper {
	public var returnType:GmlType;
	/**
	 * 
	 * @return number of arguments read, -1 on error
	 */
	public function read(oldDepth:Int, ?doc:GmlFuncDoc, ?selfType:GmlType, ?fnType:GmlType):Int {
		var newDepth = oldDepth + 1;
		var q = reader;
		linter.seqStart.setTo(q);
		var closed = false;
		var seenComma = true;
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
				if (doc.pre.endsWith(":(")) {
					// this is a self-call so selfType is funcType
					// conveniently, the suffix also happens to accurately describe
					// my feelings about doing this kind of a workaround.
					selfType = fnType;
				}
				if (!GmlTypeTools.canCastTo(selfType, doc.templateSelf, templateTypes, linter.getImports())) {
					addWarning("Can't cast " + selfType.toString(templateTypes)
						+ " to " + doc.templateSelf.toString(templateTypes)
						+ ' for ' + doc.name + "#self"
					);
				}
			}
		} else if (fnType != null) {
			fnType = fnType.resolve();
			var fnTypeKind = fnType.getKind();
			if (fnTypeKind == KFunction || fnTypeKind == KConstructor) {
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
		} else {
			argTypes = null;
			argTypesLen = 0;
			argTypeClamp = 0;
		}
		
		// special:
		var hasBufferAutoType:Bool = false;
		var bufferAutoType:GmlType = null;
		var bufferAutoTypeRet = false;
		var lastParamType:GmlType = null;
		var lastParamRet:Bool = false;
		//
		var methodAutoSelf:GmlType = null;
		//
		var hasRestParams = false;
		var restParamsNL = false;
		var restParams = null;
		var restParamsBase = null;
		var restParamsDefault = GmlTypeDef.void;
		if (argTypeClamp != 0x7fffffff && argTypes != null) switch (argTypes[argTypeClamp]) {
			case null: {};
			case TInst(_, tp, tk = KParamsOf | KParamsOfNL) if (tp.length > 0): {
				// params_of<function<int;string;void>>
				restParamsBase = tp[0];
				if (tp.length > 1) {
					restParamsDefault = tp[1];
				}
				restParamsNL = tk == KParamsOfNL;
				hasRestParams = true;
			}
			default: {};
		}
		//
		var coroutineStatus = 0; // [none, init, continue]
		var coroutineResult:GmlType = null;
		//
		if (doc != null) {
			if (argTypes != null) for (argType in argTypes) {
				switch (argType) {
					case null:
					case TInst(_, [], KBufferAutoType):
						hasBufferAutoType = true;
						break;
					default:
				}
			}
			switch (doc.returnType) {
				case null:
				case TInst(_, [], KBufferAutoType):
					hasBufferAutoType = true;
					bufferAutoTypeRet = true;
				case TInst(_, [t], KLastParamOf):
					lastParamRet = true;
					lastParamType = t;
				case TInst(name, [t], KCustom) if (name == GmlExtCoroutines.arrayTypeResultName):
					coroutineStatus = 2;
					coroutineResult = t;
				default:
			}
		}
		
		function procArgument(isUndefined:Bool):FoundError {
			var argType:GmlType;
			var argTypeInd = argc;
			if (argTypes != null) {
				if (hasRestParams && argTypeInd >= argTypeClamp) {
					if (restParams == null) {
						restParamsBase = GmlTypeTools.mapTemplateTypes(restParamsBase, templateTypes);
						restParams = switch (restParamsBase) {
							case null: [];
							case TInst(_, tp, _): tp;
							default: [];
						}
						if (restParamsNL) {
							var n = restParams.length;
							if (n > 0) restParams = restParams.slice(0, n - 1);
						}
					}
					var restInd = argTypeInd - argTypeClamp;
					if (restInd < restParams.length) {
						argType = restParams[restInd];
					} else {
						argType = restParamsDefault;
					}
				} else {
					if (argTypeInd > argTypeClamp) {
						argTypeInd = argTypeClamp;
					}
					argType = argTypeInd >= argTypesLen ? null : argTypes[argTypeInd];
				}
			} else argType = null;
			
			// read the next argument:
			var argExprType:GmlType, argExprValue:GmlLinterValue;
			if (isUndefined) {
				// don't read anything
				argExprType = GmlTypeDef.undefined;
				argExprValue = GmlLinterValue.VUndefined;
			} else {
				var _default = true;
				switch (argType) {
					case null: {};
					case TInst(_, p, KMethodFunc): {
						argType = p[0];
						// rewrite `self` for `method()`'s `fn` argument
						var funcLiteral = linter.funcLiteral;
						var lso = funcLiteral.selfOverride;
						funcLiteral.selfOverride = methodAutoSelf;
						var foundError = readExpr(newDepth, None, null, argType, templateTypes);
						funcLiteral.selfOverride = lso;
						rc(foundError);
						_default = false;
					};
					case TInst(_, [t], KLastParamOf): {
						var tParams = switch (GmlTypeTools.mapTemplateTypes(t, templateTypes)) {
							case null: [];
							case TInst(_, tp, _): tp;
							default: [];
						}
						var n = tParams.length;
						if (n > 0) {
							argType = tParams[n - 1];
						}
					};
					default:
				}
				if (_default) {
					rc(readExpr(newDepth, None, null, argType, templateTypes));
				}
				argExprType = expr.currType;
				argExprValue = expr.currValue;
			}
			
			if (coroutineResult != null && argc == 0) {
				if (isUndefined
				|| argExprValue != null && argExprValue.match(GmlLinterValue.VNumber(_, _) | GmlLinterValue.VUndefined)
				|| argExprType != null && (
					linter.valueCanCastTo(argExprValue, argExprType, GmlTypeDef.undefined, templateTypes)
					|| linter.valueCanCastTo(argExprValue, argExprType, GmlTypeDef.number, templateTypes)
				)) {
					coroutineResult = GmlTypeDef.simpleOf(GmlExtCoroutines.arrayTypeName, [coroutineResult]);
				} else {
					coroutineResult = GmlTypeDef.bool;
				}
			}
			
			if (argTypes != null && argExprType != null) {
				if (argType != null) {
					if (isFuncValue && argTypeInd == argTypeClamp) argType = argType.unwrapParam();
					//
					switch (argType) {
						case null:
						case TInst(_, params, KMethodSelf): {
							methodAutoSelf = argExprType;
							argType = params[0];
						};
						case TInst(_, params, KBufferAutoType): {
							argType = bufferAutoType;
						};
						case TInst(typeName, [], KCustom) if (hasBufferAutoType):
							if (typeName == "buffer_type") {
								var btmap = parsers.linter.misc.GmlLinterBufferAutoType.map;
								bufferAutoType = isUndefined ? null : btmap[expr.currName];
							}
						default:
					}
					//
					if (!linter.valueCanCastTo(argExprValue, argExprType, argType, templateTypes)) {
						var argName:String;
						if (doc != null) {
							argName = JsTools.or(doc.args[argTypeInd], "?");
						} else argName = null;
						addWarning("Can't cast " + argExprType.toString(templateTypes)
							+ " to " + argType.toString(templateTypes)
							+ ' for ' + argName + "#" + argc
						);
					}
				}
			}
			argc++;
			return false;
		}
		
		while (q.loop) {
			switch (peek()) {
				case LKParClose: {
					skip();
					closed = true;
					break;
				};
				case LKComma: {
					if (seenComma) {
						// todo: check if GML version supports func(,,)
						skip();
						procArgument(true);
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
					
					procArgument(false);
				}
			}
		}
		
		if (doc != null) {
			var retType = doc.returnType;
			if (bufferAutoTypeRet) {
				retType = bufferAutoType;
			}
			else if (lastParamRet) {
				var tParams = switch (GmlTypeTools.mapTemplateTypes(lastParamType, templateTypes)) {
					case null: [];
					case TInst(_, tp, _): tp;
					default: [];
				}
				var n = tParams.length;
				if (n > 0) {
					retType = tParams[n - 1];
				}
			}
			else if (coroutineResult != null) {
				retType = argc > 0 ? coroutineResult : null;
			}
			returnType = retType.mapTemplateTypes(templateTypes);
		} else if (isFuncValue) {
			returnType = argTypes[argTypesLen];
		} else returnType = null;
		
		if (!closed) {
			linter.readSeqStartError("Unclosed ()");
			return -1;
		} else return argc;
	}
}