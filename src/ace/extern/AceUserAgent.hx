package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("AceUserAgent") extern class AceUserAgent {
	static var isWin:Bool;
	static var isMac:Bool;
	static var isLinux:Bool;
	static var isOpera:Bool;
	static var isMobile:Bool;
	static var isChromeOS:Bool;
	
	static var isMacOpera(get, never):Bool;
	private static inline function get_isMacOpera():Bool {
		return isMac || isOpera;
	}
}