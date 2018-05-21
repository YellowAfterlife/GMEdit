package tools;
import haxe.Constraints.Function;
import haxe.extern.EitherType;
import js.RegExp;
import js.Syntax;

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
	
	public static inline function splitRx(s:String, at:RegExp):Array<String> {
		return s.split(cast at);
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
	
	private static var trimTrailBreak_1 = new RegExp("^([\\s\\S]*?)(\r?\n)?$", "g");
	public static function trimTrailRn(str:String, count:Int = 1):String {
		while (--count >= 0) {
			str = replaceExt(str, trimTrailBreak_1, "$1");
		}
		return str;
	}
	
	public static inline function fastSub(s:String, start:Int, len:Int):String {
		return Syntax.code("{0}.substr({1},{2})", s, start, len);
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
	
	private static var yyJson_1 = new RegExp('([ \t]+)(".*": )\\[\\]', 'g');
	private static var yyJson_2 = new RegExp('\\n', 'g');
	/** Stringifes a value while matching output format to that of GMS2 */
	@:noUsing public static function yyJson(value:Dynamic):String {
		var s = haxe.Json.stringify(value, null, "    ");
		s = replaceExt(s, yyJson_1, '$1$2[\n$1    \n$1]');
		s = replaceExt(s, yyJson_2, '\r\n');
		return s;
	}
	
}
