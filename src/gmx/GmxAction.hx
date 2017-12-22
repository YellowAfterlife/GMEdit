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
}
