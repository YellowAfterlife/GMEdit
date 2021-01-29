package ui;
import js.lib.RegExp;
import js.html.Event;
import js.html.InputElement;
import Main.aceEditor;

/**
 * If you, dear reader, are enthusiastic about color pickers,
 * consider writing a proper one and sending a pull request.
 * @author YellowAfterlife
 */
class ColorPicker {
	public static var element:InputElement;
	public static var rxGml:RegExp;
	private static var rxJs:RegExp;
	private static var prefix:String;
	private static var isBGR:Bool = true;
	private static function changed(e:Event) {
		aceEditor.session.selection.selectWord();
		var word = aceEditor.getSelectedText();
		var curr = rxGml.exec(word);
		if (curr == null) return;
		var hexc = element.value;
		hexc = hexc.toUpperCase();
		var next = rxJs.exec(hexc);
		if (next == null) return;
		if (isBGR) {
			aceEditor.insert(curr[1] + next[3] + next[2] + next[1]);
		} else {
			aceEditor.insert(curr[1] + next[1] + next[2] + next[3]);
		}
	}
	public static function open(value:String) {
		var vals = rxGml.exec(value);
		isBGR = value.charCodeAt(0) != "#".code;
		element.value = "#" + (isBGR
			? vals[4] + vals[3] + vals[2]
			: vals[2] + vals[3] + vals[4]
		);
		element.click();
	}
	public static function init() {
		element = cast Main.document.querySelector("#color-picker");
		element.addEventListener("change", changed);
		//
		var hp = "([0-9a-fA-F]{2})";
		var hp3 = hp + hp + hp;
		rxGml = new RegExp("^(0x|\\$||#)" + hp3 + "$", "");
		rxJs = new RegExp("^#" + hp3 + "$", "");
	}
}
