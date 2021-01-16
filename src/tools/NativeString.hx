package tools;
import ace.extern.AcePos;
import haxe.Constraints.Function;
import haxe.extern.EitherType;
import js.lib.RegExp;
import js.Syntax;
import tools.CharCode;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class NativeString {
	
	public static inline function fastCodeAt(s:String, index:Int):CharCode {
		return (cast s).charCodeAt(index);
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
	
	public static function splitNonEmpty(s:String, del:String):Array<String> {
		return s != null && trimBoth(s) != "" ? s.split(del) : [];
	}
	
	public static function capitalize(s:String):String {
		return s.charAt(0).toUpperCase() + s.substring(1);
	}
	
	public static inline function fastSub(s:String, start:Int, len:Int):String {
		return Syntax.code("{0}.substr({1},{2})", s, start, len);
	}
	
	public static inline function repeat(s:String, count:Int):String {
		return (cast s).repeat(count);
	}
	
	public static inline function trimRight(s:String):String {
		return (cast s).trimRight();
	}
	
	/** Trims a trailing \n or \r\n */
	public static function trimTrailRn(str:String, count:Int = 1):String {
		while (--count >= 0) {
			str = replaceExt(str, trimTrailBreak_1, "$1");
		}
		return str;
	}
	private static var trimTrailBreak_1 = new RegExp("^([\\s\\S]*?)(\r?\n)?$", "g");
	
	public static inline function trimLeft(s:String):String {
		return (cast s).trimLeft();
	}
	
	public static inline function trimBoth(s:String):String {
		return (cast s).trim();
	}
	
	public static inline function startsWith(s:String, q:String):Bool {
		return (cast s).startsWith(q);
	}
	
	public static inline function endsWith(s:String, q:String):Bool {
		return (cast s).endsWith(q);
	}
	
	public static function trimIfEndsWith(s:String, end:String):String {
		if (endsWith(s, end)) {
			return s.substring(0, s.length - end.length);
		} else return s;
	}
	
	public static inline function contains(s:String, q:String):Bool {
		return untyped s.includes(q);
	}
	
	private static var escapeRx_1:RegExp = new RegExp('([.*+?^${}()|[\\]\\/\\\\])', 'g');
	public static inline function escapeRx(s:String):String {
		return replaceExt(s, escapeRx_1, "\\$1");
	}
	
	private static var escapeProp_1:RegExp = new RegExp('(["\\\\])', 'g');
	public static inline function escapeProp(s:String):String {
		return replaceExt(s, escapeProp_1, "\\$1");
	}
	
	public static function getWholeWordRegex(s:String, ?flags:String):RegExp {
		var r:String;
		if (JsTools.rx(~/^\b/).test(s)) {
			r = "\\b" + escapeRx(s);
		} else r = escapeRx(s);
		if (JsTools.rx(~/\b$/).test(s)) r += "\\b";
		return new RegExp(r, flags);
	}
	
	/**
	 * Returns a string with a substring inserted at a position.
	 */
	public static function insert(s:String, i:Int, sub:String) {
		return s.substring(0, i) + sub + s.substring(i);
	}
	
	/**
	 * Returns spaces at the start of a string.
	 * (" text") -> " "
	 */
	public static function getPadLeft(s:String):String {
		return s.substring(0, s.length - trimLeft(s).length);
	}
	
	/**
	 * Returns spaces at the end of a string.
	 * ("text ") -> " "
	 */
	public static function getPadRight(s:String):String {
		return s.substring(trimRight(s).length);
	}
	
	/**
	 * Inserts a substring at the start of a string, after any spaces.
	 * (" text", "!!") -> " !!text"
	 */
	public static function insertAtPadLeft(s:String, what:String):String {
		var s1 = trimLeft(s);
		return s.substring(0, s.length - s1.length) + what + s1;
	}
	
	/**
	 * Inserts a substring at the end of a string, before any spaces.
	 * ("text ", "!") -> "text! "
	 */
	public static function insertAtPadRight(s:String, what:String):String {
		var s1 = trimRight(s);
		return s1 + what + s.substring(s1.length);
	}
	
	/**
	 * Inserts substrings at start/end of a string, excluding spaces.
	 * ("  text ", "1, "2") -> "  1text2 "
	 */
	public static function insertAtPadBoth(s:String, atStart:String, atEnd:String):String {
		var s1 = trimLeft(s);
		var p1 = s.substring(0, s.length - s1.length);
		var s2 = trimRight(s1);
		var p2 = s1.substring(s2.length);
		return p1 + atStart + s2 + atEnd + p2;
	}
	
	/**
	 * "non-zero-size concat"
	 * ("a", "+", "b") -> "a+b"
	 * (null, "+", "b") -> "b"
	 * ("", "+", "b") -> "b"
	 */
	public static function nzcct(s:String, sep:String, add:String):String {
		if (s == null || s == "") return add;
		if (add == null || add == "") return s;
		return s + sep + add;
	}
	
	private static var yyJson_1 = new RegExp('([ \t]+)(".*": )\\[\\]', 'g');
	private static var yyJson_2 = new RegExp('\\n', 'g');
	/** Stringifes a value while matching output format to that of GMS2 */
	@:noUsing public static inline function yyJson(value:Dynamic):String {
		return yy.YyJson.stringify(value);
	}
	
	/** Translates a single position to a row-column pair */
	public static function offsetToPos(s:String, ofs:Int):AcePos {
		var rowStart = s.lastIndexOf("\n", ofs);
		var col = ofs - rowStart;
		var row = 0;
		while (rowStart >= 0) {
			row++;
			rowStart = rowStart > 0 ? s.lastIndexOf("\n", rowStart - 1) : -1;
		}
		return new AcePos(col, row);
	}
}
