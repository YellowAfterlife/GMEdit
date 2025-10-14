package gml.type;
import gml.type.GmlType;
import haxe.ds.ReadOnlyArray;
import tools.JsTools;

/**
 * Helpers for grabbing specific type definitions
 * @author YellowAfterlife
 */
@:keep class GmlTypeDef {
	//
	public static var any:GmlType = TInst("any", [], KAny);
	public static var void:GmlType = TInst("void", [], KVoid);
	public static var undefined:GmlType = TInst("undefined", [], KUndefined);
	public static var int:GmlType = TInst("int", [], KNumber);
	public static var number:GmlType = TInst("number", [], KNumber);
	public static var bool:GmlType = TInst("bool", [], KBool);
	public static var string:GmlType = TInst("string", [], KString);
	public static var ds_map:GmlType = TInst("ds_map", [], KMap);
	public static var ds_list:GmlType = TInst("ds_list", [], KList);
	public static var ds_grid:GmlType = TInst("ds_grid", [], KGrid);
	public static var anyArray:GmlType = TInst("array", [], KArray);
	public static var anyCustomKeyArray:GmlType = TInst("ckarray", [], KCustomKeyArray);
	public static var forbidden:GmlType = TInst("forbidden", [], KVoid);
	public static var asset:GmlType = TInst("asset", [], KAsset);
	public static var global:GmlType = TInst("global", [], KGlobal);
	public static var anyFunction:GmlType = TInst("function", [], KFunction);
	public static var anyStruct:GmlType = TInst("struct", [], KStruct);
	
	public static inline function arrayOf(itemType:GmlType):GmlType {
		return TInst("array", [itemType], KArray);
	}
	public static inline function listOf(itemType:GmlType):GmlType {
		return TInst("ds_list", [itemType], KList);
	}
	public static inline function gridOf(itemType:GmlType):GmlType {
		return TInst("ds_grid", [itemType], KGrid);
	}
	public static inline function mapOf(keyType:GmlType, valType:GmlType):GmlType {
		return TInst("ds_map", [keyType, valType], KMap);
	}
	
	public static function type(name:String):GmlType {
		return TInst("type", [TInst(name, [], KCustom)], KType);
	}
	
	public static function simple(name:String):GmlType @:privateAccess {
		if (name == null) return null;
		var t = GmlTypeParser.cache[name];
		if (t == null) {
			var kind = JsTools.or(GmlTypeParser.kindMeta[name], KCustom);
			t = TInst(name, [], kind);
			GmlTypeParser.cache[name] = t;
		}
		return t;
	}
	
	public static function simpleOf(name:String, par:Array<GmlType>):GmlType {
		if (name == null) return null;
		var kind = JsTools.or(@:privateAccess GmlTypeParser.kindMeta[name], KCustom);
		return TInst(name, par, kind);
	}
	
	public static function object(name:String):GmlType @:privateAccess {
		if (name == null) return null;
		var t = GmlTypeParser.cache[name];
		if (t == null) {
			var kind = JsTools.or(GmlTypeParser.kindMeta[name], KCustom);
			t = TInst(name, [], kind);
			GmlTypeParser.cache[name] = t;
		}
		return t;
	}
	
	public static function nullable(type:GmlType):GmlType {
		return TInst("Nullable", [type], KNullable);
	}
	
	public static function rest(params:ReadOnlyArray<GmlType>):GmlType {
		return TInst("rest", params, KRest);
	}
	//
	public static inline function parse(typeString:String, ?ctx:String):GmlType {
		return GmlTypeParser.parse(typeString, ctx);
	}
}