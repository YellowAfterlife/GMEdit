package ace.extern;
import ace.AceMacro;
import electron.FileWrap;
import haxe.extern.EitherType;
import tools.Dictionary;
import tools.NativeString;

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
@:forward abstract AceCommand(AceCommandImpl) from AceCommandImpl to AceCommandImpl {
	private static function bindToAccel(b:String):String {
		return NativeString.replaceExt(b, AceMacro.jsRx(~/\b-\b/g), "+");
	}
	public function getAccelerator():String {
		var key:AceCommandKey = this.bindKey;
		if (Std.is(key, String)) return bindToAccel(key);
		var pair:AceCommandKeyPair = key;
		return bindToAccel(FileWrap.isMac ? pair.mac : pair.win);
	}
}
extern typedef AceCommandImpl = {
	bindKey:AceCommandKey,
	exec:AceWrap->Void,
	name:String,
	?readOnly: Bool,
	?scrollIntoView:String,
	?multiSelectAction:String,
}
extern typedef AceCommandKey = EitherType<String, AceCommandKeyPair>;
extern typedef AceCommandKeyPair = { win:String, mac:String };
