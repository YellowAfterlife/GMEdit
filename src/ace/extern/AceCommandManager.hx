package ace.extern;
import haxe.extern.EitherType;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
extern class AceCommandManager {
	public var recording:Bool;
	public var commands:Dictionary<Dynamic>;
	public var platform:String;
	public function on(name:String, fn:Dynamic->Void):Void;
	public function addCommand(cmd:AceCommand):Void;
	public function removeCommand(cmd:EitherType<AceCommand, String>):Void;
	public function bindKey(
		key:AceCommandKey, cmd:EitherType<String, AceWrap->Void>, ?pos:Dynamic
	):Void;
	public function execCommand(cmd:String):Void;
}
extern typedef AceCommand = {
	bindKey:AceCommandKey,
	exec:AceWrap->Void,
	name:String,
	?readOnly: Bool,
	?scrollIntoView:String,
	?multiSelectAction:String,
}
extern typedef AceCommandKey = EitherType<String, { win:String, mac:String }>;
