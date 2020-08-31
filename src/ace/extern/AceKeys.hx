package ace.extern;
import haxe.DynamicAccess;
import tools.IntDictionary;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("AceKeys")
extern class AceKeys {
	static var FUNCTION_KEYS:IntDictionary<String>;
	static var KEY_MODS:IntDictionary<String>;
	static var MODIFIER_KEYS:IntDictionary<String>;
	static var PRINTABLE_KEYS:IntDictionary<String>;
	
	static function keyCodeToString(keyCode:Int):String;
	
	static inline function get(fd:String):Int {
		return Reflect.field(AceKeys, fd);
	}
	static inline function getKey(key:Int):String {
		return Reflect.field(AceKeys, "" + key);
	}
}