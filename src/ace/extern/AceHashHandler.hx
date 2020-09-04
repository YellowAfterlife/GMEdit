package ace.extern;
import ace.extern.AceCommand;
import haxe.Constraints.Function;
import haxe.DynamicAccess;
import haxe.extern.EitherType;
import tools.Dictionary;
import tools.NativeObject;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("AceHashHandler")
extern class AceHashHandler {
	var commands:Dictionary<AceCommand>;
	
	var commandKeyBinding:Dictionary<AceOneOrMoreCommandOrName>;
	
	var platform:String;
	
	function new(?config:DynamicAccess<AceCommandInit>, ?platform:String);
	
	function addCommand(cmd:AceCommand):Void;
	
	function removeCommand(cmd:AceCommandOrName, ?keepCommand:Bool):Void;
	
	function bindKey(key:AceCommandKey, cmd:AceCommandInit, ?position:Any):Void;
	
	function addCommands(commands:DynamicAccess<AceCommandInit>):Void;
	
	function removeCommands(commands:DynamicAccess<AceCommandOrName>):Void;
	
	function bindKeys(keys:DynamicAccess<AceCommandInit>):Void;
	
	function parseKeys(keys:String):AceHashHandlerKey;
	
	function findKeyCommand(hashId:Int, key:String):AceCommand;
	
	function handleKeyboard(data:AceHashHandlerKeyContext, hashId:Int, keyString:String, keyCode:Int):Null<AceHashHandler_handleKeyboard_result>;
	
	// helpers:
	inline function getCommandNamesForKeybinding(kb:String):Array<String> {
		return AceHashHandlerHelper.getCommandNamesForKeybinding(this, kb);
	}
	inline function getKeybindingsForCommand(cmd:AceCommandOrName):Array<String> {
		return AceHashHandlerHelper.getKeybindingsForCommand(this, cmd);
	}
	inline function getKeybindingsPerCommand():Dictionary<Array<String>> {
		return AceHashHandlerHelper.getKeybindingsPerCommand(this);
	}
	inline function removeKeybindingsForCommand(cmd:AceCommandOrName):Void {
		AceHashHandlerHelper.removeKeybindingsForCommand(this, cmd);
	}
}

private class AceHashHandlerHelper {
	public static function getCommandNamesForKeybinding(hh:AceHashHandler, kb:String):Array<String> {
		var either = hh.commandKeyBinding[kb];
		if (either == null) return [];
		var names = [];
		inline function add(val:AceCommandOrName):Void {
			names.push(val.name);
		}
		if (Std.is(either, Array)) {
			for (el in (either:Array<AceCommandOrName>)) add(el);
		} else add(either);
		return names;
	}
	public static function getKeybindingsForCommand(hh:AceHashHandler, cmd:AceCommandOrName):Array<String> {
		var keybinds = [];
		NativeObject.forField(hh.commandKeyBinding, function(kb) {
			for (item in hh.commandKeyBinding[kb].toArray()) {
				if (item.equals(cmd)) {
					keybinds.push(kb);
					break;
				}
			}
		});
		return keybinds;
	}
	public static function removeKeybindingsForCommand(hh:AceHashHandler, cmd:AceCommandOrName) {
		NativeObject.forField(hh.commandKeyBinding, function(kb) {
			var either = hh.commandKeyBinding[kb];
			if (either.isArray()) {
				var arr = either.asArray();
				var i = arr.length;
				while (--i >= 0) {
					if (arr[i].equals(cmd)) arr.splice(i, 1);
				}
				if (arr.length == 0) hh.commandKeyBinding.remove(kb);
			} else {
				if (either.asItem().equals(cmd)) hh.commandKeyBinding.remove(kb);
			}
		});
	}
	public static function getKeybindingsPerCommand(hh:AceHashHandler) {
		var out = new Dictionary();
		hh.commandKeyBinding.forEach(function(key, either) {
			either.forEach(function(cmd) {
				var name = cmd.name;
				var arr = out[name];
				if (arr == null) {
					out[name] = [key];
				} else arr.push(key);
			});
		});
		return out;
	}
}

typedef AceHashHandlerKey = { key:String, hashId:Int };

typedef AceHashHandler_handleKeyboard_result = { command:AceCommandOrName }

@:forward abstract AceHashHandlerKeyContext(AceHashHandlerKeyContextImpl) {
	public function new(editor:AceWrap) {
		this = { editor: editor };
		keyChain = "";
	}
	
	public var keyChain(get, set):String;
	private inline function get_keyChain():String return Reflect.field(this, "$keyChain");
	private inline function set_keyChain(val:String) {
		Reflect.setField(this, "$keyChain", val);
		return val;
	}
}
private typedef AceHashHandlerKeyContextImpl = { editor:AceWrap };
