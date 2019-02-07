package tools;
import ace.extern.*;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
class HighlightTools {
	public static function rule(tk:Dynamic, rx:String, ?next:String):AceLangRule {
		return { token: tk, regex: rx, next: next };
	}
	public static function rtk(type:String, value:String):AceToken {
		return { type: type, value: value };
	}
	public static function rdef(tk:Dynamic):AceLangRule {
		return cast { defaultToken: tk };
	}
	
	public static function rpush(tk:Dynamic, rx:String, push:EitherType<String, Array<AceLangRule>>):AceLangRule {
		return { token: tk, regex: rx, push: push };
	}
	
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
}
