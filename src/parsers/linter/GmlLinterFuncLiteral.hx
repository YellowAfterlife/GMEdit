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

/**
 * ...
 * @author YellowAfterlife
 */
@:access(parsers.linter.GmlLinter)
class GmlLinterFuncLiteral extends GmlLinterHelper {
	public var doc:GmlFuncDoc;
	public var selfOverride:GmlType;
	
	public function read(oldDepth:Int, isFunc:Bool, isStat:Bool):FoundError {
		var name = "function";
		var isTopLevel = isFunc && isStat && oldDepth == 2 && linter.functionsAreGlobal;
		var hasName = peek() == KIdent;
		if (hasName) {
			skip();
			name = nextVal;
			if (isTopLevel) context = name;
		}
		var globalDoc = isTopLevel && hasName ? gml.GmlAPI.gmlDoc[name] : null;
		var doc = new GmlFuncDoc(name, "(", ")", [], false);
		var nextLocalType = isTopLevel ? "local" : "sublocal";
		if (skipIf(peek() == KParOpen)) { // (...args)
			var depth = 1;
			var awaitArgName = true;
			var reader = reader;
			while (reader.loop) {
				switch (next()) {
					case KParOpen, KSqbOpen, KCubOpen: depth++;
					case KParClose, KSqbClose, KCubClose: if (--depth <= 0) break;
					case KIdent: {
						if (awaitArgName) {
							var argName = nextVal;
							var argIndex = doc.args.length;
							awaitArgName = false;
							doc.args.push(nextVal);
							var imp = linter.getImports(setLocalTypes);
							var argTypeStr = null;
							var t:GmlType;
							if (skipIf(peek() == KColon)) {
								rc(linter.readTypeName());
								argTypeStr = GmlLinter.readTypeName_typeStr;
								t = GmlTypeDef.parse(argTypeStr);
							} else {
								if (globalDoc != null && globalDoc.argTypes != null) {
									t = globalDoc.argTypes[argIndex];
								} else t = null;
							}
							if (setLocalTypes) imp.localTypes[argName] = t;
							if (t != null) {
								if (doc.argTypes == null) {
									doc.argTypes = NativeArray.create(doc.args.length - 1);
								}
								doc.argTypes.push(t);
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
			rc(linter.readTypeName());
			doc.returnTypeString = GmlLinter.readTypeName_typeStr;
			nextFuncRetStatus = (doc.returnType.getKind() == KVoid ? WantNoReturn : WantReturn);
		}
		if (isFunc && skipIf(peek() == KColon)) { // : <parent>(...super args)
			rc(readCheckSkip(KIdent, "a parent type name"));
			rc(readCheckSkip(KParOpen, "opening bracket"));
			rc(linter.funcArgs.read(oldDepth + 1) < 0);
		}
		if (isFunc) { // `function() constructor`?
			skipIf(peek() == KIdent && nextVal == "constructor");
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
		
		if (selfOverride != null) {
			var self0z = linter.__selfType_set;
			var self0t = linter.__selfType_type;
			linter.__selfType_set = true;
			linter.__selfType_type = selfOverride;
			var foundError = readStat(0);
			linter.__selfType_set = self0z;
			linter.__selfType_type = self0t;
			rc(foundError);
		} else {
			rc(readStat(0));
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