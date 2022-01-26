package ui;
import ace.extern.AceAutoCompleteItem;
import gml.file.GmlFile;
import js.html.OptionElement;
import js.lib.RegExp;
import tools.NativeString;
import ui.project.ProjectProperties;

/**
 * The thing you see when you press Ctrl+Shift+T
 * @author YellowAfterlife
 */
@:expose("CommandPalette")
class CommandPalette {
	public static var lookupMap:Map<String, CommandDef> = new Map();
	public static var lookupItems:Array<AceAutoCompleteItem> = [];
	public static function add(cmd:CommandDef) {
		var name = cmd.name;
		if (lookupMap[name] == null) {
			lookupItems.push({value:name});
		}
		lookupMap[name] = cmd;
	}
	public static function remove(cmd:CommandDef) {
		var name = cmd.name;
		if (lookupMap[name] != null) {
			tools.NativeArray.removeFirst(lookupItems, (c)->c.name == name);
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
		add({
			name: "Edit keybinds",
			exec: function() {
				editors.EditKeybindings.open();
			}
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
