package gml.type;
import ace.AceGmlTools;
import gml.GmlAPI;
import gml.GmlNamespace;
import gml.type.GmlType;
import haxe.ds.ReadOnlyArray;
import js.lib.RegExp;
import parsers.GmlReader;
import tools.Dictionary;
import tools.JsTools;
using tools.NativeString;
import ace.extern.AceTokenType;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class GmlTypeTools {
	public static var builtinTypes:Array<String> = [
		"any", "Any", "void", "Void",
		"bool", "int", "number", "string", 
		"array", "Array",
		"type", "Type",
		"struct", "instance",
	];
	public static var kindMap:Dictionary<AceTokenType> = Dictionary.fromKeys(builtinTypes, "namespace");
	
	public static inline var templateItemName:String = "TemplateItem";
	public static inline var templateSelfName:String = "TemplateSelf";
	
	/** If this might be a namespace, returns the name */
	public static function getNamespace(t:GmlType):String {
		return switch (t) {
			case null: null;
			case TInst(name, _, KCustom): name;
			default: null;
		}
	}
	
	/** If this is a TInst, returns the GmlTypeKind */
	public static function getKind(t:GmlType):Null<GmlTypeKind> {
		return switch (t) {
			case null: null;
			case TInst(_, _, k): k;
			default: null;
		}
	}
	
	public static inline function isNullable(t:GmlType):Bool {
		return getKind(t) == KNullable;
	}
	
	public static inline function isType(t:GmlType):Bool {
		return getKind(t) == KType;
	}
	
	public static inline function isArray(t:GmlType):Bool {
		return getKind(t) == KArray;
	}
	
	/** Distinctly, Any is either null (lack of type info) or KAny */
	public static function isAny(t:GmlType):Bool {
		return switch (t) {
			case null: true;
			case TInst(_, _, KAny): true;
			default: false;
		}
	}
	
	/** Extracts T from A<T> */
	public static function unwrapParam(t:GmlType, ind:Int = 0):GmlType {
		return switch (t) {
			case null: null;
			case TInst(_, p, _): p[ind];
			default: null;
		}
	}
	
	/**
	 * Runs f on each element of array and returns an updated immutable array.
	 * Unchanged elements will be reused and changing nothing will return back the array.
	 */
	public static function mapArray(arr:ReadOnlyArray<GmlType>, f:GmlType->GmlType):ReadOnlyArray<GmlType> {
		var out:Array<GmlType> = null;
		for (i => t1 in arr) {
			var t2 = f(t1);
			if (t2 != t1) {
				if (out == null) out = arr.slice(0, i);
				out.push(t2);
			} else {
				if (out != null) out.push(t1);
			}
		}
		return out != null ? out : arr;
	}
	
	/**
	 * Runs f on each sub-type of t and returns the updated immutable type.
	 * Unchanged elements will be reused and changing nothing will return back the input.
	 */
	public static function map(t:GmlType, f:GmlType->GmlType):GmlType {
		switch (t) {
			case TInst(n1, tp1, k1): {
				var tp2 = mapArray(tp1, f);
				return tp2 != tp1 ? TInst(n1, tp2, k1) : t;
			};
			case TEither(et1): {
				var et2 = mapArray(et1, f);
				return et2 != et1 ? TEither(et2) : t;
			};
			default: return t;
		}
	}
	
	/**
	 * (Map<K, V>, [int, string]) -> Map<int, string>
	 */
	public static function mapTemplateTypes(t:GmlType, templateTypes:Array<GmlType>):GmlType {
		function f(t:GmlType):GmlType {
			return switch (t) {
				case null: null;
				case TTemplate(_, ind, _): return templateTypes[ind];
				default: t.map(f);
			}
		}
		return f(t);
	}
	
	public static function equals(a:GmlType, b:GmlType, ?tpl:Array<GmlType>):Bool {
		switch (b) {
			case null:
			case TInst(_, bp, KTemplateSelf):
				switch (a) {
					case null: return true;
					case TInst(_, ap, _):
						for (i in 0 ... bp.length) equals(ap[i], bp[i], tpl);
						return true;
					default: return false;
				}
			case TTemplate(_, i, c):
				if (tpl == null) return true;
				if (tpl[i] != null) {
					return equals(a, tpl[i]);
				} else {
					// this is clearly not a very good idea
					if (a != null) {
						if (c == null || canCastTo(a, c, tpl)) {
							tpl[i] = a;
						} else return false;
					}
					return true;
				}
			default:
		}
		switch (a) {
			case null, TInst(_, _, KAny): return inline isAny(b);
			case TInst(n1, tp1, k1):
				switch (b) {
					case null: return false;
					case TInst(n2, tp2, k2):
						if (k1 != k2) return false;
						if (k1 == KCustom && n1 != n2) return false;
						for (i => p1 in tp1) {
							if (!p1.equals(tp2[i], tpl)) return false;
						}
						return true;
					default: return false;
				}
			case TEither(et1):
				var et2 = switch (b) {
					case null: return false;
					case TEither(et): et;
					default: return false;
				}
				var en = et1.length;
				if (en != et2.length) return false;
				var ei1 = -1;
				while (++ei1 < en) {
					var et = et1[ei1];
					var ei2 = -1;
					while (++ei2 < en) {
						if (et.equals(et2[ei2], tpl)) break;
					}
					if (ei2 >= en) return false;
				}
				return true;
			case TAnon(fm1):
				var fm2 = switch (b) {
					case null: return false;
					case TAnon(f): f;
					default: return false;
				}
				var n1 = 0;
				for (name => field in fm1.fields) {
					n1 += 1;
					if (!field.type.equals(fm2.fields[name].type, tpl)) return false;
				}
				return n1 == fm2.fields.size();
			case TTemplate(i1, _): return false;
		}
	}
	
	static function canCastToAnyOf(from:GmlType, toArr:ReadOnlyArray<GmlType>, ?tpl:Array<GmlType>):Bool {
		for (to in toArr) if (canCastTo(from, to, tpl)) return true;
		return false;
	}
	
	public static function canCastTo(from:GmlType, to:GmlType, ?tpl:Array<GmlType>, ?imp:GmlImports):Bool {
		var kfrom = getKind(from), kto = getKind(to);
		if (kfrom == KVoid || kto == KVoid) return false;
		
		if (from == to) return true;
		if (from == null || to == null) return true;
		if (kfrom == KAny || kto == KAny) return true;
		
		if (from.equals(to, tpl)) return true;
		
		if (kto == KNullable) {
			// undefined -> number?
			if (kfrom == KUndefined) return true;
			// number -> number?
			if (kfrom != KNullable && from.canCastTo(to.unwrapParam(), tpl)) return true;
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
		
		switch ([from, to]) {
			case [TEither(et1), TEither(et2)]: { // each member of from must cast to some member of to
				for (t1 in et1) if (!canCastToAnyOf(t1, et2, tpl)) return false;
				return true;
			}
			case [_, TEither(et2)]: return canCastToAnyOf(from, et2, tpl);
			case [TInst(n1, p1, k1), TInst(n2, p2, k2)]: {
				switch (k2) {
					// allow bool<->number casts:
					case KNumber: if (k1 == KBool) return true;
					case KBool: if (k1 == KNumber) return true;
					case KArray: // var v:Enum should be allowed for array access
						if (p2.length == 0 && GmlAPI.gmlEnums.exists(n1)) return true;
					case KObject:
						var ns = GmlAPI.gmlNamespaces[n1];
						if (JsTools.nca(ns, ns.isObject)) return true;
					case KAsset:
						var ns = GmlAPI.gmlNamespaces[n1];
						if (JsTools.nca(ns, ns.isObject)) return true;
						var nk = GmlAPI.gmlKind[n1];
						if (nk != null && nk.startsWith("asset.")) return true;
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
				
				if (AceGmlTools.findNamespace(n1, imp, function(ns:GmlNamespace) {
					var depth = 0;
					while (ns != null && ++depth < GmlNamespace.maxDepth) {
						for (itf in ns.interfaces) if (ns.name == n2) return true;
						ns = ns.parent;
						if (JsTools.nca(ns, ns.name == n2)) return true;
					}
					return false;
				})) return true;
			};
			case [TAnon(a1), TInst(n2, [], KCustom)]: {
				// todo: see if anon can be unified
			}
			default:
		}
		return false;
	}
	
	public static function toString(type:GmlType, ?tpl:Array<GmlType>):String {
		switch (type) {
			case null: return "?";
			case TInst(_, [p], KNullable): return toString(p, tpl) + "?";
			case TInst(name, params, kind): {
				var s:String = name;
				if (params.length > 0) {
					s += "<";
					for (i => tp in params) {
						if (i > 0) s += ", ";
						s += toString(tp, tpl);
					}
					s += ">";
				}
				return s;
			};
			case TEither(types): {
				var s = "(";
				for (i => tp in types) {
					if (i > 0) s += "|";
					s += toString(tp, tpl);
				}
				return s + ")";
			};
			case TAnon(anon): {
				var s = "{ ";
				var sep = false;
				anon.fields.forEach(function(k, fd) {
					if (sep) s += ", "; else sep = true;
					s += k + ": " + toString(fd.type, tpl);
				});
				if (sep) s += " ";
				return s + "}";
			};
		case TTemplate(name, ind, c):
			var tt = JsTools.nca(tpl, tpl[ind]);
			if (tt != null) return toString(tt);
			var s = name + "#" + ind;
			if (c != null) s = "(" + s + ":" + c.toString() + ")";
			return s;
		}
	}
	
	public static function patchTemplateItems(s:String, templateItems:Array<GmlTypeTemplateItem>):String {
		if (templateItems == null) return s;
		for (i => tn in templateItems) {
			s = s.replaceExt(tn.regex, function() {
				var ct = tn.constraint;
				if (tn.constraint != null) {
					return '$templateItemName<${tn.name},_$i,$ct>';
				} else return '$templateItemName<${tn.name},_$i>';
			});
		}
		return s;
	}
	
	public static function getSelfCallDoc(self:GmlType, imp:GmlImports):GmlFuncDoc {
		return JsTools.nca(self, AceGmlTools.findSelfCallDoc(self, imp));
	}
}
class GmlTypeTemplateItem {
	public var name:String;
	public var regex:RegExp;
	public var constraint:String;
	public function new(name:String, ?ct:String) {
		this.name = name;
		regex = name.getWholeWordRegex("g");
		constraint = ct;
	}
}