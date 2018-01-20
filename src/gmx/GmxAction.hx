package gmx;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxAction {
	public static function isCode(action:SfGmx):Bool {
		return action.findText("libid") == "1"
			&& action.findText("id") == "603"
			&& action.findText("whoName") == "self";
	}
	public static function getCode(action:SfGmx):String {
		if (isCode(action)) {
			return action.find("arguments").find("argument").find("string").text;
		} else return null;
	}
	public static function makeCodeBlock(code:String):SfGmx {
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
