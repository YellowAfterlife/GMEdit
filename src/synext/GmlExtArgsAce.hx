package synext;
import tools.CharCode;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class GmlExtArgsAce {
	public static function getHiddenLines(args:String):Int {
		var i = 0;
		var depth = 0;
		var state = 0;
		var found = 0;
		var seenOpt = false;
		while (i < args.length) {
			var c:CharCode = args.fastCodeAt(i++);
			switch (c) {
				case "(".code, "[".code, "{".code: depth++;
				case ")".code, "]".code, "}".code: depth--;
				case ",".code: {
					if (depth == 0) {
						state = 0;
						seenOpt = false;
					}
				};
				case "?".code: {
					if (state == 0 && !seenOpt) {
						seenOpt = true;
						found += 1;
					}
				};
				case "=".code: {
					if (state == 1) {
						state = 2;
						found += 1;
					}
				};
				case '"'.code: {
					while (i < args.length) {
						c = args.fastCodeAt(i++);
						if (c == "\\".code) {
							i += 1;
						} else if (c == '"'.code) break;
					}
				};
				case "'".code: {
					while (i < args.length) {
						c = args.fastCodeAt(i++);
						if (c == "'".code) break;
					}
				};
				case _ if (depth == 0 && state == 0 && c.isIdent0()): {
					// skip ident:
					while (i < args.length) {
						c = args.fastCodeAt(i);
						if (c.isIdent1()) {
							i += 1;
						} else break;
					}
					state = 1;
				};
				default:
			}
		}
		return found;
	}
}