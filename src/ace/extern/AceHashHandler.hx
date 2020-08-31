package ace.extern;
import ace.extern.AceCommand;
import haxe.Constraints.Function;
import haxe.DynamicAccess;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("AceHashHandler")
extern class AceHashHandler {
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
}

typedef AceHashHandlerKey = { key:String, hashId:Int };

typedef AceHashHandler_handleKeyboard_result = { command:EitherType<String, AceCommand> }

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
