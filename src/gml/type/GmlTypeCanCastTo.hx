package gml.type;
import ace.AceGmlTools;
import gml.type.GmlType.GmlTypeAnonField;
import gml.type.GmlType.GmlTypeKind;
import haxe.ds.ReadOnlyArray;
import tools.JsTools;
import tools.NativeObject;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlTypeCanCastTo {
	static function canCastToAnyOf(from:GmlType, toArr:ReadOnlyArray<GmlType>, ?tpl:Array<GmlType>, ?imp:GmlImports):Bool {
		for (to in toArr) if (canCastTo(from, to, tpl, imp)) return true;
		return false;
	}
	
	/** Whether this is an isExplicit cast (`val as Type`) */
	public static var isExplicit:Bool = false;
	/** Whether casting `void` should be allowed (only for return type in `function<>`) */
	public static var allowVoidCast:Bool = false;
	/** Whether this is in a boolean operator and it's okay to cast instances to it */
	public static var isBoolOp:Bool = false;
	/** Note: linter updates these in the constructor */
	public static var allowImplicitNullCast:Bool = false;
	public static var allowImplicitBoolIntCasts:Bool = false;
	public static var allowNullToAny:Bool = false;
	
	public static function canCastTo(from:GmlType, to:GmlType, ?tpl:Array<GmlType>, ?imp:GmlImports):Bool {
		from = from.resolve();
		to = to.resolve();
		var kfrom:GmlTypeKind = GmlTypeTools.getKind(from);
		var kto:GmlTypeKind = GmlTypeTools.getKind(to);
		if (!allowVoidCast) {
			if (kfrom == KVoid || kto == KVoid) return false;
		}
		
		if (from == to) return true;
		if (from == null || to == null) return true;
		if (kfrom == KAny || kto == KAny) return true;
		
		if (from.equals(to, tpl)) return true;
		
		if (kto == KNullable) {
			// undefined -> number?
			if (kfrom == KUndefined) return true;
			// number -> number?
			if (kfrom != KNullable && from.canCastTo(to.unwrapParam(), tpl, imp)) return true;
		}
		
		if (kfrom == KUndefined) {
			if (allowNullToAny) return true;
			var nsName = to.getNamespace();
			var ns = nsName != null ? GmlAPI.gmlNamespaces[nsName] : null;
			if (ns != null && ns.isNullable) return true;
		}
		
		if (isExplicit) {
			if (kfrom == KNullable) {
				if (from.unwrapParam().canCastTo(to, tpl, imp)) return true;
			} else switch (from) {
				case TEither(et1): {
					for (t in et1) if (canCastTo(t, to, tpl, imp)) return true;
				};
				default:
			}
		} else if (kfrom == KNullable && allowImplicitNullCast) {
			if (from.unwrapParam().canCastTo(to, tpl, imp)) return true;
		}
		
		if (kto == KStruct) switch (from) {
			case TInst(name, _, _):
				if (!canCastTo(from, GmlTypeDef.asset, tpl, imp)) {
					var ns = GmlAPI.gmlNamespaces[name];
					if (JsTools.nca(ns, ns.canCastToStruct)) return true;
				}
			case TAnon(_): return true;
			default:
		}
		
		if (tpl != null) {
			to = GmlTypeTools.mapTemplateTypes(to, tpl);
			if (to == null) return false;
		}
		
		switch ([from, to]) {
			case [TTemplate(n1, i1, c1), t]: {
				return canCastTo(c1, t, tpl, imp);
			};
			case [TEither(et1), TEither(et2)]: { // each member of from must cast to some member of to
				for (t1 in et1) if (!canCastToAnyOf(t1, et2, tpl, imp)) return false;
				return true;
			}
			case [_, TEither(et2)]: return canCastToAnyOf(from, et2, tpl, imp);
			case [TEither(et1), _]: // each member of from must cast to
				for (t1 in et1) if (!canCastTo(t1, to, tpl, imp)) return false;
				return true;
			case [TSpecifiedMap(mapMeta), TInst(_, p, KMap)]: {
				if (p.length == 0) return true;
				if (!canCastTo(p[0], GmlTypeDef.string, tpl, imp)) return false;
				var vt = p[1];
				if (vt == null || vt.getKind() == KAny) return true;
				if (!canCastTo(mapMeta.defaultType, vt, tpl, imp)) return false;
				for (mapField in mapMeta.fieldList) {
					if (!canCastTo(mapField.type, vt)) return false;
				}
				return true;
			};
			case [TInst(_, [], KMap), TSpecifiedMap(_)]: return true;
			case [TInst(n1, p1, k1), TInst(n2, p2, k2)]: {
				// allow function->script casts
				if (k1 == KFunction && n2 == "script") return true;
				
				switch (k2) {
					// allow bool<->number casts:
					case KNumber: if (k1 == KBool) return allowImplicitBoolIntCasts || isExplicit;
					case KBool: if (k1 == KNumber) return allowImplicitBoolIntCasts || isExplicit;
					
					case KArray: // var v:Enum should be allowed for array access
						if (p2.length == 0 && GmlAPI.gmlEnums.exists(n1)) return true;
					case KObject:
						var ns = GmlAPI.gmlNamespaces[n1];
						if (JsTools.nca(ns, ns.isObject)) return true;
						if (GmlAPI.gmlKind[n1] == "asset.object") return true;
					case KAsset:
						var ns = GmlAPI.gmlNamespaces[n1];
						if (JsTools.nca(ns, ns.isObject)) return true;
						var nk = GmlAPI.gmlKind[n1];
						if (nk != null && nk.startsWith("asset.")) return true;
					case KFunction:
						if (k1 != KFunction) return false;
						var i = p2.length;
						if (i == 0 || p1.length == 0) return true; // any-functions
						if (p1.length != i) return false;
						if (--i >= 0) { // return value
							var couldVoidCast = allowVoidCast;
							allowVoidCast = true;
							var ok = p1[i].canCastTo(p2[i], tpl, imp);
							allowVoidCast = couldVoidCast;
							if (!ok) return false;
						}
						while (--i >= 0) { // arguments
							if (!p1[i].canCastTo(p2[i], tpl, imp)) return false;
						}
						return true;
					case KCustomKeyArray if (k1 == KArray):
						if (p1[0].isAny()) return true;
					default:
				}
				
				if (k1 == k2 && (k1 != KCustom || n1 == n2)) {
					// allow Array<T>->Array or Array<T>->Array<?>:
					var i = p1.length;
					while (--i >= 0) if (p2[i] != null) break;
					if (i < 0) return true;
					// and Array<?>->Array<T>?
					i = p2.length;
					while (--i >= 0) if (p1[i] != null) break;
					if (i < 0) return true;
				}
				
				var checkBoolOp = kto == KBool && isBoolOp;
				if (checkBoolOp && kfrom == KObject) return true;
				if (AceGmlTools.findNamespace(n1, imp, function(ns:GmlNamespace) {
					var depth = 0;
					var found = false;
					while (ns != null && ++depth < GmlNamespace.maxDepth) {
						if (checkBoolOp && ns.isObject) { found = true; break; }
						for (itf in ns.interfaces) {
							if (checkBoolOp && itf.isObject) { found = true; break; }
							if (itf.name == n2) { found = true; break; }
						}
						if (found) break;
						ns = ns.parent;
						if (JsTools.nca(ns, ns.name == n2)) { found = true; break; }
					}
					return found;
				})) return true;
			};
			case [TAnon(a1), TInst(n2, [], KCustom)]: {
				var ns = GmlAPI.gmlNamespaces[n2];
				if (ns != null) {
					var ok = true;
					for (fdc in ns.getInstComp(0, false)) {
						var fd = fdc.name;
						var af = a1.fields[fd];
						if (af == null || !af.type.canCastTo(ns.getInstType(fd))) {
							ok = false;
							break;
						}
					}
					if (ok) return true;
				}
			}
			case [TAnon(a1), TAnon(a2)]: {
				var ok = true;
				NativeObject.forField(a2.fields, function(fd:String) {
					var afd2 = a2.fields[fd];
					var afd1 = a1.fields[fd];
					if (afd1 == null || !afd1.type.canCastTo(afd2.type)) ok = false;
				});
				return ok;
			};
			default:
		}
		return false;
	}
}