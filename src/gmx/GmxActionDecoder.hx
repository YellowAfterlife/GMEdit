package gmx;

import gmx.GmxAction;
import gmx.GmxActionValues;
import tools.Aliases;

class GmxActionDecoder {
	public static var errorText:String;
	public static function decode(a:GmxActionData):GmxActionDecoderResult {
		errorText = null;
		inline function error(s:ErrorText):GmxActionDecoderResult {
			errorText = s;
			return null;
		}
		if (a.libid != 1) {
			return error("Actions from user-created libraries are not supported.");
		}
		//
		var applyTo = a.who;
		var applyNS = applyTo != null && applyTo != "self";
		//
		var result;
		switch (a.id) {
			case 603: {
				var code = a.args[0].s;
				if (applyNS) {
					code = "#with " + applyTo + "\r\n" + code;
					return { code: code, kind: With };
				}
				return { code: code, kind: Code };
			};
			case 601: {
				result = "action_execute_script " + a.args[0].s;
				for (i in 1 ... a.args.length) {
					result += ", " + a.args[i].s;
				}
			};
			case 604: result = "action_inherited";
			case 605: result = "// " + a.args[0].s;
			case 203: result = "action_kill_object";
			case 408: result = "action_if" + (a.not ? "_not " : " ") + a.args[0].s;
			case 422: result = "{";
			case 424: result = "}";
			//
			case 112: result = "action_wrap " + GmxActionValues.action_wrap_args[a.args[0].int];
			default: return error('DnD action #${a.id} (${a.fn}) is not supported.');
		}
		//
		if (applyNS) {
			result = '#action with $applyTo $result';
		} else result = '#action $result';
		//
		return { code: result, kind: Action };
	}
	private static var rxHeader = ~/^\/\/\/\/?(.*)/;
	/** NB! May modify the action if it extracts the header comment out of it **/
	public static function actionSep(snip:GmxActionDecoderResult) {
		if (snip.kind == Code) {
			// additional code blocks should be denoted with `#section`
			
			var out = null;
			// If a code block starts with a `/// title`, make that `#section title`
			snip.code = rxHeader.map(snip.code, function(e:EReg) {
				var cap = e.matched(1);
				out = "\n#section";
				if (cap.charCodeAt(0) != " ".code) out += "|";
				out += cap;
				return "";
			});
			return out ?? ("\n#section" + (snip.code != "" ? "\n" : ""));
		} else return "\n";
	}
	public static function decodeArray(actions:Array<GmxActionData>):GmlCode {
		var out = "";
		for (i => action in actions) {
			var snip = decode(action);
			if (snip == null) return null;
			if (i > 0) out += actionSep(snip);
			out += snip.code;
		}
		return out;
	}
}
typedef GmxActionDecoderResult = {
	var code: GmlCode;
	var kind: GmxActionDecoderKind;
};
enum GmxActionDecoderKind {
	Action;
	Code;
	With;
}