package tools;
import haxe.Constraints.Function;
import haxe.extern.EitherType;
import js.RegExp;

/**
 * ...
 * @author YellowAfterlife
 */
extern class NativeString {
	public static inline function split(s:String, d:EitherType<String, RegExp>):Array<String> {
		return untyped s.split(d);
	}
	public static inline function replace(
		s:String, what:EitherType<String, RegExp>, by:EitherType<String, Function>
	):String {
		return untyped s.replace(what, by);
	}
}
