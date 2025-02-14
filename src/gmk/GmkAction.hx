package gmk;
import gmx.GmxActionDecoder;
import gmx.GmxAction;
import gmx.SfGmx;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmkAction {
	public static var errorText:String;
	
	static function getApplyTo(action:SfGmx):String {
		var val = action.findText("appliesTo");
		if (val.startsWith(".")) return val.substring(1);
		return val;
	}
	public static function getActionData(action:SfGmx):GmxActionData {
		var a:GmxActionData = {
			libid: Std.parseInt(action.get("library")),
			id: Std.parseInt(action.get("id")),
			who: getApplyTo(action),
			fn: action.findText("functionName"),
			not: (action.findText("not") == "true"),
			// todo: more things
		};
		var argsNode = action.find("arguments");
		if (argsNode != null) {
			a.args = argsNode.findAll("argument").map(arg -> { kind: Text, s: arg.text });
		}
		return a;
	}
	public static function getCode(action:SfGmx):String {
		var out = GmxActionDecoder.decode(getActionData(action));
		return out?.code;
	}
	public static function getCodeMulti(nodes:Array<SfGmx>) {
		var actions = nodes.map(getActionData);
		return GmxActionDecoder.decodeArray(actions);
	}
	public static function makeCodeBlock(code:String):SfGmx {
		errorText = "Not supported!";
		return null;
	}
}