package gml.type;
import ace.AceGmlTools;
import gml.GmlAPI;
import gml.GmlNamespace;
import gml.type.GmlType;
import gml.type.GmlTypeCanCastTo;
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
	
	public static function unwrapParams(t:GmlType):ReadOnlyArray<GmlType> {
		return switch (t) {
			case null: null;
			case TInst(_, p, _): p;
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
			case THint(hint, t1):
				var t2 = map(t1, f);
				return t2 != t1 ? THint(hint, t2) : t;
			default: return t;
		}
	}
	
	/**
	 * (Map<K, V>, [int, string]) -> Map<int, string>
	 */
	public static function mapTemplateTypes(t:GmlType, templateTypes:ReadOnlyArray<GmlType>):GmlType {
		if (templateTypes == null) return t;
		function f(t:GmlType):GmlType {
			return switch (t) {
				case null: null;
				case TTemplate(_, ind, c): {
					var t = templateTypes[ind];
					return t != null ? t : c;
				};
				default: t.map(f);
			}
		}
		return f(t);
	}
	
	public static function resolve(self:GmlType, depth:Int = 0):GmlType {
		if (++depth >= 128) return null;
		switch (self) {
			case null: return null;
			case THint(hint, type): return resolve(type, depth);
			case TInst(name, params, kind):
				var td = kind == KCustom ? GmlAPI.gmlTypedefs[name] : null;
				if (td != null) {
					return mapTemplateTypes(td, params);
				}
				return self;
			default: return self;
		}
	}
	
	public static function resolveRec(self:GmlType, depth:Int = 0):GmlType {
		if (++depth >= 128) return null;
		switch (self) {
			case null: return null;
			case THint(hint, type): return resolve(type, depth);
			case TInst(name, params, kind):
				var td = kind == KCustom ? GmlAPI.gmlTypedefs[name] : null;
				if (td != null) {
					var resolvedParams = params.map((p) -> resolve(p, depth));
					return mapTemplateTypes(td, resolvedParams);
				}
				var newParams = null;
				for (i => p0 in params) {
					var p1 = resolve(p0, depth);
					if (p1 != p0) {
						if (newParams == null) newParams = params.copy();
						newParams[i] = p1;
					}
				}
				return newParams != null ? TInst(name, newParams, kind) : self;
			case TEither(types):
				var newTypes = null;
				for (i => p0 in types) {
					var p1 = resolve(p0, depth);
					if (p1 != p0) {
						if (newTypes == null) newTypes = types.copy();
						newTypes[i] = p1;
					}
				}
				return newTypes != null ? TEither(newTypes) : self;
			default: return self;
		}
	}
	
	public static function equals(a:GmlType, b:GmlType, ?tpl:Array<GmlType>):Bool {
		a = resolve(a); b = resolve(b);
		switch (b) {
			case null:
			case THint(_, type): return equals(a, type, tpl);
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
			case THint(_, type): return equals(type, b, tpl);
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
				for (name => fd1 in fm1.fields) {
					n1 += 1;
					var fd2 = fm2.fields[name];
					if (fd2 == null) return false;
					if (!fd1.type.equals(fd2.type, tpl)) return false;
				}
				return n1 == fm2.fields.size();
			case TTemplate(i1, _): return false;
		}
	}
	
	public static inline function canCastTo(from:GmlType, to:GmlType, ?tpl:Array<GmlType>, ?imp:GmlImports):Bool {
		return GmlTypeCanCastTo.canCastTo(from, to, tpl, imp);
	}
	
	public static function toString(type:GmlType, ?tpl:Array<GmlType>):String {
		switch (type) {
			case null: return "?";
			case THint(hint, type): return hint + ":" + toString(type, tpl);
			case TInst(_, [p], KNullable): return toString(p, tpl) + "?";
			case TInst(_, p, KTemplateItem):
				return p.length < 3 ? toString(p[0]) : "(" + toString(p[0]) + ":" + toString(p[2]) + ")";
			case TInst(_, p, KFunction):
				var n = p.length - 1;
				if (n < 0) return "function";
				var s = "function(";
				var i = -1; while (++i < n) {
					if (i > 0) s += ", ";
					s += ":" + toString(p[i], tpl);
				}
				return s + GmlFuncDoc.parRetArrow + toString(p[n], tpl);
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
			var s = name;
			#if debug
			s += "#" + ind;
			#end
			if (c != null) s = '($s:' + c.toString() + ')';
			return s;
		}
	}
	
	public static function patchTemplateItems(s:String, templateItems:Array<GmlTypeTemplateItem>):String {
		if (s == null || templateItems == null) return s;
		for (i => tn in templateItems) {
			s = s.replaceExt(tn.regex, function() {
				var ct = tn.constraint;
				if (tn.constraint != null) {
					return '$templateItemName<${tn.name};_$i;$ct>';
				} else return '$templateItemName<${tn.name};_$i>';
			});
		}
		return s;
	}
	
	public static function getSelfCallDoc(self:GmlType, imp:GmlImports):GmlFuncDoc {
		return JsTools.nca(self, AceGmlTools.findSelfCallDoc(self, imp));
	}
}
