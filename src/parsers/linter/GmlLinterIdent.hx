package parsers.linter;
import ace.AceGmlTools;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.GmlImports;
import gml.GmlNamespace;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import tools.JsTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLinterIdent {
	public static var type:GmlType = null;
	public static var func:GmlFuncDoc = null;
	public static function read(linter:GmlLinter, currName:String) {
		var currType:GmlType = null;
		var currFunc:GmlFuncDoc = null;
		@:privateAccess do {
			switch (currName) {
				case "self":
					currType = linter.getSelfType();
					currFunc = currType.getSelfCallDoc(linter.getImports());
					break;
				case "other":
					currType = linter.getOtherType();
					currFunc = currType.getSelfCallDoc(linter.getImports());
					break;
				case "global":
					currType = GmlTypeDef.global;
					break;
				case "true", "false":
					currType = GmlTypeDef.bool;
					break;
			}
			
			var imp:GmlImports = linter.getImports();
			var locals = linter.editor.locals[linter.context];
			if (locals != null && locals.kind.exists(currName)) {
				if (imp != null) {
					currType = imp.localTypes[currName];
					currFunc = currType.getSelfCallDoc(imp);
				} else { // locals without type information
					currType = null;
					currFunc = null;
				}
				break;
			}
			
			var lam = linter.editor.lambdas[linter.context];
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
						currType = currFunc != null ? currFunc.getFunctionType() : null;
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
			
			var t = linter.getSelfType();
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
				if (!found && wantWarn && linter.optRequireFields) {
					linter.addWarning('Variable $currName is not part of $tn');
				}
			}
		} while (false);
		type = currType;
		func = currFunc;
	}
}