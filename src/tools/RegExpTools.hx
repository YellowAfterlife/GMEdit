package tools;
import js.lib.RegExp;

/**
 * ...
 * @author YellowAfterlife
 */
class RegExpTools {
	/**
	 * As a faithful exec() loop, if your RegExp is not global, this will softlock.
	 */
	public static inline function each(rx:RegExp, s:String, fn:RegExpMatch->Void, pos:Int = 0, till:Int = -1) {
		if (till < 0) till = s.length;
		rx.lastIndex = pos;
		var mt = rx.exec(s);
		while (mt != null && mt.index < till) {
			fn(mt);
			mt = rx.exec(s);
		}
	}
}