package tools;

/**
 * ...
 * @author YellowAfterlife
 */
class ERegTools {
	public static function each(r:EReg, s:String, f:EReg->Void):Void {
		var i:Int = 0;
		while (r.matchSub(s, i)) {
			f(r);
			var p = r.matchedPos();
			i = p.pos + p.len;
		}
	}
}
