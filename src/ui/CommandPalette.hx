package ui;
import js.html.OptionElement;
import tools.NativeString;

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
	public static function init() {
		add({
			name: "Preferences",
			exec: function() Preferences.open()
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
