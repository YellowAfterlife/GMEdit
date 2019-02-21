package ui;
import tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GlobalCommands {
	public static var lookupText:String = "";
	public static var lookupMap:Map<String, GlobalCommand> = new Map();
	public static var lookupList:Array<String> = [];
	public static function add(name:String, func:Void->Void, ?hint:String) {
		if (lookupMap[name] == null) {
			lookupText += name + "\n";
			lookupList.push(name);
		}
		lookupMap[name] = new GlobalCommand(name, func, hint);
	}
	public static function init() {
		add("Preferences", function() {
			Preferences.open();
		});
	}
}
class GlobalCommand {
	public var name:String;
	public var func:Void->Void;
	public var hint:String;
	public function new(name:String, func:Void->Void, hint:String) {
		this.name = name;
		this.func = func;
		this.hint = hint;
	}
}
