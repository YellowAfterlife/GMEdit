package ;
import haxe.extern.Rest;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("console") extern class Console {
	public static function log(values:Rest<Any>):Void;
	public static function error(values:Rest<Any>):Void;
	public static function warn(values:Rest<Any>):Void;
}
