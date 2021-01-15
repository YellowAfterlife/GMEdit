package gml.type;
import gml.type.GmlType;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlTypeDef {
	//
	public static var undefined:GmlType = TInst("undefined", [], KUndefined);
	public static var number:GmlType = TInst("number", [], KNumber);
	public static var bool:GmlType = TInst("bool", [], KBool);
	public static var string:GmlType = TInst("string", [], KString);
	public static inline function array(itemType:GmlType):GmlType {
		return TInst("array", [itemType], KArray);
	}
	public static function type(name:String):GmlType {
		return TInst("type", [TInst(name, [], KCustom)], KType);
	}
	
	public static function simple(name:String):GmlType @:privateAccess {
		if (name == null) return null;
		var t = GmlTypeParser.cache[name];
		if (t == null) {
			t = TInst(name, [], KCustom);
			GmlTypeParser.cache[name] = t;
		}
		return t;
	}
	
	public static function object(name:String):GmlType @:privateAccess {
		if (name == null) return null;
		var t = GmlTypeParser.cache[name];
		if (t == null) {
			t = TInst(name, [], KCustom);
			GmlTypeParser.cache[name] = t;
		}
		return t;
	}
	//
	public static inline function parse(typeString:String):GmlType {
		return GmlTypeParser.parse(typeString);
	}
}