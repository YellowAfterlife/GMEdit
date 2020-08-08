package tools;
import js.lib.RegExp;

/**
 * ...
 * @author YellowAfterlife
 */
class RegExpCache {
	var regex:RegExp = null;
	var pattern:String = null;
	var flags:String;
	public function new(?flags:String) {
		this.flags = flags;
	}
	public function update(pt:String, ?defPattern:String):RegExp {
		if (pt == null) pt = defPattern;
		if (pattern == pt) return regex;
		pattern = pt;
		if (pt != null) {
			try {
				regex = new RegExp(pt, flags);
			} catch (x:Dynamic) {
				Main.console.error('Error compiling a regular expression from pattern `$pt`:', x);
				regex = null;
			}
		} else regex = null;
		return regex;
	}
}