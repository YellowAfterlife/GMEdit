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
	public static inline function matchRx(s:String, rx:RegExp):Array<String> {
		return untyped s.match(rx);
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
	public static inline function startsWith(s:String, q:String):Bool {
		return untyped s.startsWith(q);
	}
	public static inline function endsWith(s:String, q:String):Bool {
		return untyped s.endsWith(q);
	}
	public static inline function contains(s:String, q:String):Bool {
		return s.indexOf(q) != -1;
	}
	private static var escapeRx_1:RegExp = new RegExp('([.*+?^${}()|[\\]\\/\\\\])', 'g');
	public static inline function escapeRx(s:String):String {
		return replaceExt(s, escapeRx_1, "\\$1");
	}
	private static var escapeProp_1:RegExp = new RegExp('(["\\\\])', 'g');
	public static inline function escapeProp(s:String):String {
		return replaceExt(s, escapeProp_1, "\\$1");
	}
	public static function insert(s:String, i:Int, sub:String) {
		return s.substring(0, i) + sub + s.substring(i);
	}
}
