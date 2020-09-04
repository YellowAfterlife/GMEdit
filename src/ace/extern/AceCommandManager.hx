package ace.extern;
import ace.AceMacro;
import ace.extern.AceHashHandler;
import electron.FileWrap;
import haxe.extern.EitherType;
import tools.Dictionary;
import tools.NativeString;
import ace.extern.AceCommand;

/**
 * ...
 * @author YellowAfterlife
 */
extern class AceCommandManager extends AceHashHandler {
	public var recording:Bool;
	
	public function on(name:String, fn:Dynamic->Void):Void;
	
	public function execCommand(cmd:String):Void;
}
