package ace.gml;
import ace.extern.AceLangRule;
import ace.extern.AceToken;
import ace.extern.AceTokenType;
import editors.EditCode;
import gml.GmlAPI;
import gml.GmlEnum;
import gml.GmlImports;
import gml.GmlNamespace;
import ace.AceMacro.*;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import tools.JsTools;
import tools.HighlightTools.*;

/**
 * ...
 * @author YellowAfterlife
 */
class AceGmlHighlightIdents {
	public static inline function getGlobalType(name:String, fallback:String) {
		return jsOrx(
			GmlAPI.gmlKind[name],
			GmlAPI.extKind[name],
			GmlAPI.stdKind[name],
			synext.GmlExtCoroutines.keywordMap[name],
			fallback
		);
	}
	//
	public static function getLocalType_1(editor:EditCode, name:String, scope:String, canLocal:Bool):String {
		var kind:String;
		//
		var lambdas = editor.lambdas[scope];
		if (lambdas != null && (kind = lambdas.kind[name]) != null) return kind;
		//
		if (canLocal) {
			var locals = editor.locals[scope];
			if (locals != null && (kind = locals.kind[name]) != null) return kind;
		}
		//
		var imports = editor.imports[scope];
		if (imports != null && (kind = imports.kind[name]) != null) return kind;
		//
		return null;
	}
	public static function getLocalType(editor:EditCode, row:Int, name:String, canLocal:Bool):String {
		if (row != null) {
			var scope = editor.session.gmlScopes.get(row);
			if (scope != null) {
				return getLocalType_1(editor, name, scope, canLocal);
			} else return null;
		} else return null;
	}
	static function genIdentPairFunc_getInstType(field:String, localTypeNS:String, ns:GmlNamespace, ns2:GmlNamespace) {
		var fdType:AceTokenType;
		if (ns != null) {
			fdType = ns.getInstKind(field);
			if (fdType == null) {
				if (ns2 != null) {
					fdType = jsOrx(ns2.getInstKind(field), "typeerror");
				} else fdType = "typeerror";
			}
		} else if (ns2 != null) {
			fdType = jsOrx(ns2.getInstKind(field), "typeerror");
		} else {
			var en = GmlAPI.gmlEnums[localTypeNS];
			if (en != null) {
				fdType = en.items[field] ? "enumfield" : "enumerror";
			} else { // local.something
				fdType = getGlobalType(field, "field");
			}
		}
		return fdType;
	}
	public static function matchIdent(editor:EditCode, row:Int, name:String, def:AceTokenType, isMFunc:Bool):AceTokenType {
		var type:String;
		var scope:String = row != null ? editor.session.gmlScopes.get(row) : null;
		type = scope != null ? getLocalType_1(editor, name, scope, !isMFunc) : null;
		if (type == null) type = getGlobalType(name, null);
		if (type == null) do { // attempt to pull out self-type:
			var locals = editor.locals[scope];
			if (locals == null || locals.hasWith) break;
			var localType = AceGmlTools.getSelfType({session:editor.session, scope:scope});
			if (localType == null) break;
			var localTypeNS = localType.getNamespace();
			if (localTypeNS == null) break;
			var imports = editor.imports[scope];
			type = genIdentPairFunc_getInstType(name, localTypeNS,
				JsTools.nca(imports, imports.namespaces[localTypeNS]),
				GmlAPI.gmlNamespaces[localTypeNS]);
			if (type == "field") type = def;
		} while (false);
		if (type == null) type = def;
		return type;
	}
	public static function genIdent(editor:EditCode, isMFunc:Bool, fieldDef:AceTokenType):AceLangRule {
		var def = isMFunc ? "identifier" : fieldDef;
		return {
			regex: '[a-zA-Z_][a-zA-Z0-9_]*\\b',
			onMatch: function(
				value:String, state:AceLangRuleState, stack:Array<String>, line:String, row:Int
			) {
				return matchIdent(editor, row, value, def, isMFunc);
			},
		};
	}
	static function genIdentPairFunc(editor:EditCode, isMFunc:Bool, fieldDef:String) {
		var def = isMFunc ? "identifier" : fieldDef;
		return function(
			value:String, state:AceLangRuleState, stack:Array<String>, line:String, row:Int
		) {
			var values:Array<String> = jsThis.splitRegex.exec(value);
			var object = values[1];
			var field = values[5];
			var objType:AceTokenType, fdType:AceTokenType;
			//
			if (object == "global") {
				objType = "keyword";
				fdType = "globalfield";
			} else {
				objType = null;
				fdType = null;
				var en:GmlEnum;
				var scope = JsTools.nca(row != null, editor.session.gmlScopes.get(row));
				var imp:GmlImports = null, ns:GmlNamespace, ns2:GmlNamespace;
				var localType:GmlType, localTypeNS:String;
				var checkSelf = false;
				if (scope != null) {
					imp = editor.imports[scope];
					// save some trouble:
					var checkStatics = false;
					if (object == "self") {
						objType = "keyword";
						localType = AceGmlTools.getSelfType({session:editor.session, scope:scope});
					} else if (object == "other") {
						objType = "keyword";
						localType = null;
						// we could, but we would be consistently wrong inside with(){} blocks
						//localType = AceGmlTools.getOtherType({session:editor.session, scope:scope});
					} else if (GmlAPI.gmlKind[object] == "asset.object") {
						objType = "asset.object";
						localType = GmlTypeDef.object(object);
					} else {
						localType = null;
						checkStatics = true;
					}
					// perhaps a NameSpace.staticField?:
					if (checkStatics) {
						for (step in (imp != null ? 0 : 1) ... 2) {
							ns = step != 0 ? GmlAPI.gmlNamespaces[object] : imp.namespaces[object];
							//
							if (ns != null) {
								objType = ns.isObject ? "asset.object" : "namespace";
								fdType = ns.staticKind[field];
								if (fdType != null) break;
							}
							//
							if (step == 0) {
								// handles `#import EnumName in Namespace`
								var e1 = imp.longenEnum[object];
								if (e1 != null) {
									en = GmlAPI.gmlEnums[e1];
									if (en != null && en.items[field]) {
										fdType = "enumfield";
										break;
									}
								}
							}
						}
						if (objType != null && fdType == null) fdType = "identifier";
					}
					// evidently that wasn't a namespace, perhaps a local variable?
					if (!checkStatics || objType == null) {
						if (objType == null) {
							objType = getLocalType_1(editor, object, scope, !isMFunc);
							localType = JsTools.nca(imp, imp.localTypes[object]);
						}
						localTypeNS = JsTools.nca(localType, localType.getNamespace());
						if (localTypeNS != null) {
							fdType = genIdentPairFunc_getInstType(field, localTypeNS,
								JsTools.nca(imp, imp.namespaces[localTypeNS]),
								GmlAPI.gmlNamespaces[localTypeNS]);
						} else switch (localType) {
							case null: //
							case TAnon(inf):
								fdType = inf.fields.exists(field) ? "field" : "typeerror";
							default:
						}
					}
					// implicit self-vars
					if (objType == null) {
						var locals = editor.locals[scope];
						checkSelf = locals != null && !locals.hasWith;
					}
				} // has scope
				if (objType == null) {
					// well that sucks, maybe an enum?:
					en = GmlAPI.gmlEnums[object];
					if (en != null) {
						objType = "enum";
						fdType = en.items[field] ? "enumfield" : "enumerror";
					} else { // that's just built-ins then:
						objType = getGlobalType(object, null);
						if (objType == null && checkSelf) do {
							localType = AceGmlTools.getSelfType({session:editor.session, scope:scope});
							if (localType == null) break;
							localTypeNS = localType.getNamespace();
							if (localTypeNS == null) break;
							ns = JsTools.nca(imp, imp.namespaces[localTypeNS]);
							ns2 = GmlAPI.gmlNamespaces[localTypeNS];
							objType = genIdentPairFunc_getInstType(object, localTypeNS,
								JsTools.nca(imp, imp.namespaces[localTypeNS]),
								GmlAPI.gmlNamespaces[localTypeNS]);
							if (objType == "field") objType = def;
						} while (false);
						if (objType == null) objType = def;
						fdType = getGlobalType(field, "field");
					}
				} else if (fdType == null) { // found type, but no field (and not an error)
					fdType = getGlobalType(field, "field");
				}
			}
			var tokens:Array<AceToken> = [rtk(objType, object)];
			if (values[2] != "") tokens.push(rtk("text", values[2]));
			tokens.push(rtk("punctuation.operator", values[3]));
			if (values[4] != "") tokens.push(rtk("text", values[4]));
			tokens.push(rtk(fdType, field));
			return tokens;
		};
	}
	public static function genIdentPair(editor:EditCode, isMFunc:Bool, fieldDef:String):AceLangRule {
		return {
			regex: '([a-zA-Z_]\\w*)(\\s*)(\\.)(\\s*)([a-zA-Z_]\\w*|)',
			onMatch: genIdentPairFunc(editor, isMFunc, fieldDef)
		};
	}
}