package gmx;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxAction {
	public static var errorText:String;
	public static function getCode(action:SfGmx):String {
		if (action.findText("libid") != "1") {
			errorText = "Actions from user-created libraries are not supported.";
			return null;
		}
		if (action.findText("whoName") != "self") {
			errorText = "Non-self-applied actions are not supported.";
			return null;
		}
		var aid = action.findText("id");
		switch (Std.parseInt(aid)) {
			case 603: return action.find("arguments").find("argument").find("string").text;
			case 604: return "#action action_inherited\r\n";
			default: {
				errorText = "Action #" + aid + "(" + action.findText("functionname")
					+ ") is not supported.";
				return null;
			};
		}
	}
	static function makeDndBlock(id:Int, fn:String) {
		var action = new SfGmx("action");
		action.addTextChild("libid", "1");
		action.addTextChild("id", "" + id);
		action.addTextChild("kind", "0");
		action.addTextChild("userelative", "0");
		action.addTextChild("isquestion", "0");
		action.addTextChild("useapplyto", "0");
		action.addTextChild("exetype", "1");
		action.addTextChild("functionname", fn);
		action.addTextChild("codestring", "");
		action.addTextChild("whoName", "self");
		action.addTextChild("relative", "0");
		action.addTextChild("isnot", "0");
		return action;
	}
	public static function makeCodeBlock(code:String):SfGmx {
		if (code.startsWith("#action ")) {
			switch (code.substring(7).trimBoth()) {
				case "action_inherited": return makeDndBlock(604, "action_inherited");
				default: {
					errorText = "Action `" + code + "` is not supported.";
					return null;
				}
			}
		}
		var action = new SfGmx("action");
		action.addTextChild("libid", "1");
		action.addTextChild("id", "603");
		action.addTextChild("kind", "7");
		action.addTextChild("userelative", "0");
		action.addTextChild("isquestion", "0");
		action.addTextChild("useapplyto", "-1");
		action.addTextChild("exetype", "2");
		action.addTextChild("functionname", "");
		action.addTextChild("codestring", "");
		action.addTextChild("whoName", "self");
		action.addTextChild("relative", "0");
		action.addTextChild("isnot", "0");
		var arguments = new SfGmx("arguments");
		action.addChild(arguments);
		var argument = new SfGmx("argument");
		argument.addTextChild("kind", "1");
		if (code == "") code = "\r\n";
		argument.addTextChild("string", code);
		arguments.addChild(argument);
		return action;
	}
}
