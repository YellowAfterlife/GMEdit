package parsers.seeker;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerProcWith {
	public static function proc(seeker:GmlSeekerImpl):Void {
		var q = seeker.reader;
		seeker.locals.hasWith = true;
		q.skipSpaces1();
		var hasCurly:Bool;
		if (q.skipIfEquals("(".code)) {
			q.skipBalancedParenExpr();
		} else {
			q.skipVarExpr(q.version, "{".code);
		}
		q.skipSpaces1();
		if (q.peek() == "{".code) {
			if (seeker.withStartsAtCurlyDepth < 0) {
				seeker.withStartsAtCurlyDepth = seeker.curlyDepth + 1;
			}
		}
	}
}