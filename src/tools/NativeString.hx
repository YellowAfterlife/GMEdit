package tools;
import haxe.Constraints.Function;
import haxe.extern.EitherType;
import js.RegExp;

/**
 * ...
 * @author YellowAfterlife
 */
class NativeString {
	public static inline function splitReg(s:String, d:RegExp):Array<String> {
		return s.split(cast d);
	}
	public static inline function replaceExt(
		s:String, what:EitherType<String, RegExp>, by:EitherType<String, Function>
	):String {
		return untyped s.replace(what, by);
	}
	public static function capitalize(s:String):String {
		return s.charAt(0).toUpperCase() + s.substring(1);
	}
	public static inline function trimRight(s:String):String {
		return untyped s.trimRight();
	}
	public static inline function trimLeft(s:String):String {
		return untyped s.trimLeft();
	}
	public static inline function trimBoth(s:String):String {
		return untyped s.trim();
	}
}
