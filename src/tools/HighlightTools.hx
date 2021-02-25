package tools;
import ace.AceMacro;
import ace.extern.*;
import ace.extern.AceLangRule;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
class HighlightTools {
	public static var jsThisAsRule(get, never):AceLangRule;
	private static inline function get_jsThisAsRule():AceLangRule {
		return js.Lib.nativeThis;
	}
	
	public static function rule(tk:AceLangRuleTokenInit, rx:String, ?next:AceLangRuleNextInit):AceLangRule {
		return { token: tk, regex: rx, next: next };
	}
	public static function rtk(type:String, value:String):AceToken {
		return { type: type, value: value };
	}
	public static function rdef(tk:Dynamic):AceLangRule {
		return cast { defaultToken: tk };
	}
	
	public static function rpush(tk:Dynamic, rx:String, push:AceLangRuleNextInit):AceLangRule {
		return { token: tk, regex: rx, push: push };
	}
	
	public static function rmatch(mt:AceLangRuleMatch, rx:String, ?next:AceLangRuleNextInit):AceLangRule {
		return { onMatch: mt, regex: rx, next: next };
	}
	/**
	 * ["a", "t1", "b", "t2"] -> { token: ["t1","t2"], regex: "(a)(b)" }
	 */
	public static function rulePairs(pairs_rx_tk:Array<String>, ?next:String):AceLangRule {
		var rs = "";
		var i = 0;
		var tokens = [];
		while (i < pairs_rx_tk.length) {
			rs += "(" + pairs_rx_tk[i] + ")";
			tokens.push(pairs_rx_tk[i + 1]);
			i += 2;
		}
		return { token: tokens, regex: rs, next: next };
	}
	public static function rawRulePairs(pairs_rx_tk:Array<String>, ?next:String):AceLangRule {
		var rs = "";
		var i = 0;
		var tokens = [];
		while (i < pairs_rx_tk.length) {
			rs += pairs_rx_tk[i];
			tokens.push(pairs_rx_tk[i + 1]);
			i += 2;
		}
		return { token: tokens, regex: rs, next: next };
	}
	public static function rpushPairs(pairs_rx_tk:Array<String>, push:AceLangRuleNextInit):AceLangRule {
		var rs = "";
		var i = 0;
		var tokens = [];
		while (i < pairs_rx_tk.length) {
			rs += "(" + pairs_rx_tk[i] + ")";
			tokens.push(pairs_rx_tk[i + 1]);
			i += 2;
		}
		return { token: tokens, regex: rs, push: push };
	}
	
	public static function rulePairsExt(rule:HighlightTools_rpairs):AceLangRule {
		var pairs = rule.pairs;
		var isRaw = false;
		if (pairs != null) {
			AceMacro.jsDelete(rule.pairs);
		} else {
			pairs = rule.rawPairs;
			if (pairs != null) {
				isRaw = true;
				AceMacro.jsDelete(rule.rawPairs);
			} else throw "Why call rulePairsExt without pairs/rawPairs";
		}
		//
		var tokens = [];
		var regex = "";
		var i = 0, n = pairs.length;
		while (i < n) {
			regex += isRaw ? pairs[i] : '(' + pairs[i] + ')';
			if (i + 1 < n) tokens.push(pairs[i + 1]);
			i += 2;
		}
		rule.token = tokens;
		rule.regex = regex;
		return rule;
	}
	
	public static function rpop2(c:AceLangRuleState, st:Array<AceLangRuleState>):AceLangRuleState {
		st.shift();
		st.shift();
		return JsTools.or(st.shift(), "start");
	}
}

typedef HighlightTools_rpairs = { > AceLangRule,
	?pairs:Array<String>,
	?rawPairs:Array<String>,
}
