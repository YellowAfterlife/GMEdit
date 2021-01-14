package ace.extern;
import ace.extern.AceLangRule;
import ace.extern.AceTokenType;

/**
 * ...
 * @author YellowAfterlife
 */
class AceLangRuleDefTools {
	public static function getRegex(defs:Array<AceLangRuleDef>):String {
		var regex = "";
		for (def in defs) switch (def) {
			case Token(rx, _): regex += '($rx)';
			case OptToken(rx, _): regex += '($rx)?';
			case OptGroup(arr): regex += '(?:' + getRegex(arr) + ')?';
		}
		return regex;
	}
	public static function getTokenTypes(defs:Array<AceLangRuleDef>, ?out:Array<AceTokenType>):Array<AceTokenType> {
		if (out == null) out = [];
		for (def in defs) switch (def) {
			case Token(_, t), OptToken(_, t): out.push(t);
			case OptGroup(arr): getTokenTypes(arr, out);
		}
		return out;
	}
	public static function toRule(defs:Array<AceLangRuleDef>, ?out:AceLangRule):AceLangRule {
		if (out == null) out = {};
		out.regex = getRegex(defs);
		out.token = getTokenTypes(defs);
		return out;
	}
}