package gml.type;
import ace.AceGmlTools;
import gml.type.GmlType;
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
	public static var kindMap:Dictionary<AceTokenType> = Dictionary.fromKeys([
		"Any", "any", "undefined",
		"number", "string", "bool", // primitives
		"array", "type", "Array", "Type",
		"ds_list", "ds_map", "ds_grid",
	], "namespace");
	
	public static function equals(a:GmlType, b:GmlType):Bool {
		switch (a) {
			case null: return b == null;
			case TInst(n1, tp1, k1):
				switch (b) {
					case null: return false;
					case TInst(n2, tp2, k2):
						if (k1 != k2) return false;
						if (k1 == KCustom && n1 != n2) return false;
						for (i => p1 in tp1) {
							if (!p1.equals(tp2[i])) return false;
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
						if (et.equals(et2[ei2])) break;
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
					if (!field.type.equals(fm2.fields[name].type)) return false;
				}
				return n1 == fm2.fields.size();
		}
	}
	
	public static function getNamespace(t:GmlType):String {
		return switch (t) {
			case null: null;
			case TInst(name, _, KCustom): name;
			default: null;
		}
	}
	
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
	
	public static function unwrapParam(t:GmlType):GmlType {
		return switch (t) {
			case null: null;
			case TInst(_, p, _): p[0];
			default: null;
		}
	}
	
	public static function canCastTo(from:GmlType, to:GmlType):Bool {
		if (from == null || to == null) return true;
		if (from == to) return true;
		if (from.equals(to)) return true;
		switch (to) {
			case TEither(et):
				for (t in et) if (from.equals(t)) return true;
			default:
		}
		return false;
	}
	
	public static function toString(type:GmlType):String {
		return switch (type) {
			case null: "?";
			case TInst(name, params, kind): {
				var s:String = name;
				if (params.length > 0) {
					s += "<";
					for (i => tp in params) {
						if (i > 0) s += ", ";
						s += toString(tp);
					}
					s += ">";
				}
				return s;
			};
			case TEither(types): {
				var s = "(";
				for (i => tp in types) {
					if (i > 0) s += "|";
					s += toString(tp);
				}
				return s + ")";
			};
			case TAnon(anon): {
				var s = "{ ";
				var sep = false;
				anon.fields.forEach(function(k, fd) {
					if (sep) s += ", "; else sep = true;
					s += k + ": " + toString(fd.type);
				});
				if (sep) s += " ";
				return s + "}";
			};
		}
	}
	
	public static function getSelfCallDoc(self:GmlType, imp:GmlImports):GmlFuncDoc {
		return JsTools.nca(self, AceGmlTools.findSelfCallDoc(self, imp));
	}
}
