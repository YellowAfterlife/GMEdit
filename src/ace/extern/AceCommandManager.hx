package ace.extern;
import ace.AceMacro;
import electron.FileWrap;
import haxe.extern.EitherType;
import tools.Dictionary;
import tools.NativeString;
import ace.extern.AceCommand;

/**
 * ...
 * @author YellowAfterlife
 */
extern class AceCommandManager {
	public var recording:Bool;
	public var commands:Dictionary<AceCommand>;
	public var commandKeyBinding:Dictionary<AceCommand>;
	public var platform:String;
	public function on(name:String, fn:Dynamic->Void):Void;
	public function addCommand(cmd:AceCommand):Void;
	public function removeCommand(cmd:EitherType<AceCommand, String>):Void;
	public function bindKey(
		key:AceCommandKey, cmd:EitherType<String, AceWrap->Void>, ?pos:Dynamic
	):Void;
	public function execCommand(cmd:String):Void;
}
