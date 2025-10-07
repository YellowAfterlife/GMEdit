package parsers.linter;
import tools.NativeArray;
import gml.type.GmlTypeDef;
import gml.GmlFuncDoc;
import gml.type.GmlType;
import parsers.linter.GmlLinter.GmlLinterReturnStatus;
import parsers.linter.GmlLinterKind;
import tools.Aliases;
import tools.Dictionary;
import tools.JsTools;
import tools.macros.GmlLinterMacros.*;
using gml.type.GmlTypeTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:access(parsers.linter.GmlLinter)
class GmlLinterFuncLiteral extends GmlLinterHelper {
	public var doc:GmlFuncDoc;
	public var selfOverride:GmlType;
	
	static var defaultOptions:GmlLinterFuncLiteralOptions = {};
	public function read(oldDepth:Int, isFunc:Bool, isStat:Bool, ?options:GmlLinterFuncLiteralOptions):FoundError {
		var name = "function";
		var isTopLevel = isFunc && isStat && oldDepth == 2 && linter.functionsAreGlobal;
		if (options == null) options = defaultOptions;
		var arrowOpts = options.arrowFunc;
		var targetType = options.targetType;
		var templateTypes = options.templateTypes;
		var targetArgTypes:Array<GmlType> = null;
		if (targetType != null) {
			var mappedType = targetType;
			if (templateTypes != null) {
				mappedType = mappedType.mapTemplateTypes(templateTypes);
			}
			switch (mappedType) {
				case TInst(_, tp, KFunction | KConstructor) if (tp.length > 0):
					targetArgTypes = tp.slice(0, tp.length - 1);
				default:
			}
		}
		//
		var hasName = arrowOpts == null && peek() == LKIdent;
		if (hasName) {
			skip();
			name = nextVal;
			if (isTopLevel) context = name;
		}
		var globalDoc = isTopLevel && hasName ? gml.GmlAPI.gmlDoc[name] : null;
		var globalDocArgTypes = globalDoc != null ? globalDoc.argTypes : null;
		var globalDocArgOffset = globalDoc != null && tools.NativeString.startsWith(
			globalDoc.post, GmlFuncDoc.parRetArrow + synext.GmlExtCoroutines.arrayTypeResultName
		) ? 1 : 0;
		var doc = new GmlFuncDoc(name, "(", ")", [], false);
		var nextLocalType = isTopLevel ? "local" : "sublocal";
		//
		function procArgTypePost(argName:String, t:GmlType, argTypeStr:String) {
			if (setLocalTypes) {
				var imp = linter.getImports(setLocalTypes);
				imp.localTypes[argName] = t;
			}
			if (t != null) {
				if (doc.argTypes == null) {
					doc.argTypes = NativeArray.create(doc.args.length - 1);
				}
				doc.argTypes.push(t);
			} else {
				if (doc.argTypes != null) doc.argTypes.push(t);
			}
			if (setLocalVars) editor.locals[context].add(argName, nextLocalType,
				JsTools.nca(argTypeStr, "type " + argTypeStr)
			);
		}
		var wantPar = null;
		var awaitArgName = true;
		if (arrowOpts != null) {
			if (arrowOpts.state == AfterEmptyPar) {
				wantPar = false;
			} else {
				doc.args.push(arrowOpts.firstArgName);
				wantPar = arrowOpts.state != AfterArrow && arrowOpts.state != AfterEmptyPar;
				awaitArgName = arrowOpts.state == AfterComma;
				if (arrowOpts.state == AfterColon) { // 
					rc(linter.readTypeName());
					var argTypeStr = GmlLinter.readTypeName_typeStr;
					var t = GmlTypeDef.parse(argTypeStr);
					procArgTypePost(arrowOpts.firstArgName, t, argTypeStr);
				} else {
					var firstTargetArgType = targetArgTypes != null ? targetArgTypes[0] : null;
					if (firstTargetArgType != null) {
						procArgTypePost(arrowOpts.firstArgName, firstTargetArgType, null);
					} else {
						procArgTypePost(arrowOpts.firstArgName, null, null);
					}
				}
			}
		}
		if (wantPar == null) { // let's ponder whether we want (...args)
			if (skipIf(peek() == LKParOpen)) {
				wantPar = true;
			} else if (isFunc) {
				return readExpect("function literal arguments");
			} else wantPar = false;
		}
		if (wantPar) { // (...args)
			var depth = 1;
			var reader = reader;
			while (reader.loop) {
				switch (next()) {
					case LKParOpen, LKSqbOpen, LKCubOpen: depth++;
					case LKParClose, LKSqbClose, LKCubClose: if (--depth <= 0) break;
					case LKIdent: {
						if (awaitArgName) {
							var argName = nextVal;
							var argIndex = doc.args.length;
							awaitArgName = false;
							doc.args.push(argName);
							var argTypeStr = null;
							var t:GmlType;
							if (skipIf(peek() == LKColon)) {
								// arg:type
								rc(linter.readTypeName());
								argTypeStr = GmlLinter.readTypeName_typeStr;
								t = GmlTypeDef.parse(argTypeStr);
							} else {
								if (globalDocArgTypes != null) {
									// no :type, but we have this hinted already
									t = globalDoc.argTypes[argIndex + globalDocArgOffset];
								} else if (targetArgTypes != null) {
									t = targetArgTypes[argIndex];
								} else t = null;
							}
							procArgTypePost(argName, t, argTypeStr);
						}
					};
					case LKComma: if (depth == 1) awaitArgName = true;
					default:
				}
			}
		}
		//
		var nextFuncRetStatus = GmlLinterReturnStatus.NoReturn;
		if (arrowOpts != null) {
			if (arrowOpts.state != AfterArrow) {
				if (next() != LKArrowFunc) {
					var ctx = switch (arrowOpts.state) {
						case AfterColon: "because it had a (name:type)";
						case AfterComma: "because it had comma-separated words";
						case AfterEmptyPar: "(or maybe you just forgot to put anything in parentheses)";
						default: null;
					}
					return readExpect("a => after what looked like an arrow-function"
						+ (ctx != null ? " " + ctx : ""));
				}
			}
		} else {
			if (skipIf(peek() == LKArrow)) { // `->returnType`
				rc(linter.readTypeName());
				doc.returnTypeString = GmlLinter.readTypeName_typeStr;
				nextFuncRetStatus = (doc.returnType.getKind() == KVoid ? WantNoReturn : WantReturn);
			}
			if (isFunc && skipIf(peek() == LKColon)) { // : <parent>(...super args)
				rc(readCheckSkip(LKIdent, "a parent type name"));
				rc(readCheckSkip(LKParOpen, "opening bracket"));
				rc(linter.funcArgs.read(oldDepth + 1) < 0);
			}
			if (isFunc) { // `function() constructor`?
				if (skipIf(peek() == LKIdent && nextVal == "constructor")) {
					doc.isConstructor = true;
					doc.hasReturn = true;
					doc.returnTypeString = "any";
					nextFuncRetStatus = WantNoReturnConstructor;
					if (!hasName) {
						// An anonymous constructor! Good luck with that
						selfOverride = GmlTypeDef.any;
					}
				}
			}
		}
		//
		var oldLocalNames = linter.localNamesPerDepth;
		var oldLocalKinds = linter.localKinds;
		var oldFuncDoc = linter.currFuncDoc;
		var oldFuncRetStatus = linter.currFuncRetStatus;
		var oldLocalTokenType = linter.localVarTokenType;
		
		linter.localNamesPerDepth = [];
		linter.localKinds = new Dictionary();
		linter.currFuncDoc = doc;
		linter.currFuncRetStatus = nextFuncRetStatus;
		linter.localVarTokenType = nextLocalType;
		
		inline function readFuncBody():FoundError {
			if (arrowOpts == null || skipIfPeek(LKSemico) || peek() == LKCubOpen) {
				return readStat(0);
			} else {
				var trouble = readExpr(0);
				linter.currFuncRetStatus = HasReturn;
				return trouble;
			}
		}
		if (selfOverride != null) {
			var self0z = linter.__selfType_set;
			var self0t = linter.__selfType_type;
			linter.__selfType_set = true;
			linter.__selfType_type = selfOverride;
			var foundError = readFuncBody();
			linter.__selfType_set = self0z;
			linter.__selfType_type = self0t;
			rc(foundError);
		} else {
			rc(readFuncBody());
		}
		
		switch (linter.currFuncRetStatus) {
			case HasReturn:
				if (nextFuncRetStatus == NoReturn) doc.returnTypeString = "";
			case WantReturn:
				addWarning("The function is marked as having a return but does not return anything.");
			case NoReturn:
				doc.hasReturn = false;
			default:
		}
		
		linter.localNamesPerDepth = oldLocalNames;
		linter.localKinds = oldLocalKinds;
		linter.currFuncDoc = oldFuncDoc;
		linter.currFuncRetStatus = oldFuncRetStatus;
		linter.localVarTokenType = oldLocalTokenType;
		
		this.doc = doc;
		return false;
	}
}
typedef GmlLinterFuncLiteralOptions = {
	?arrowFunc:{
		state:GmlLinterFuncLiteralArgsArrowState,
		firstArgName:String,
		?retType:GmlType,
	},
	?targetType:GmlType,
	?templateTypes:Array<GmlType>,
};
enum abstract GmlLinterFuncLiteralArgsArrowState(Int) {
	var AfterColon;
	var AfterComma;
	var AfterArrow;
	var AfterEmptyPar;
}