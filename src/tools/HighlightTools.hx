package tools;
import ace.extern.*;

/**
 * ...
 * @author YellowAfterlife
 */
class HighlightTools {
	public static function rule(tk:Dynamic, rx:String, ?next:String):AceLangRule {
		return { token: tk, regex: rx, next: next };
	}
}
