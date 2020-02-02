package ui;
import js.html.OptionElement;
import js.lib.RegExp;
import tools.NativeString;
import ui.project.ProjectProperties;

/**
 * ...
 * @author YellowAfterlife
 */
@:expose("CommandPalette")
class CommandPalette {
	public static var lookupText:String = "";
	public static var lookupMap:Map<String, CommandDef> = new Map();
	public static var lookupList:Array<String> = [];
	public static function add(cmd:CommandDef) {
		var name = cmd.name;
		if (lookupMap[name] == null) {
			lookupText += name + "\n";
			lookupList.push(name);
		}
		lookupMap[name] = cmd;
	}
	public static function remove(cmd:CommandDef) {
		var name = cmd.name;
		if (lookupMap[name] != null) {
			var rx = new RegExp("^" + NativeString.escapeRx(name) + "\n", "m");
			lookupText = NativeString.replaceExt(lookupText, rx, "");
			lookupList.remove(name);
			lookupMap.remove(name);
		}
	}
	public static function init() {
		add({
			name: "Preferences",
			exec: function() Preferences.open()
		});
		add({
			name: "Project properties",
			exec: function() ProjectProperties.open()
		});
		add({
			name: "Reload GMEdit",
			exec: function() Main.document.location.reload()
		});
	}
}
typedef CommandDef = {
	/// display name
	name:String,
	
	/// function to be ran
	exec:Void->Void,
	
	/// associated keybind (shown on the right)
	?key:String,
	
	/// mouseover text
	?title:String,
}
