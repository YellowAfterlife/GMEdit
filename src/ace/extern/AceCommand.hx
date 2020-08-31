package ace.extern;
import ace.extern.AceUserAgent;
import haxe.extern.EitherType;
import tools.NativeString;
import haxe.Constraints;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract AceCommand(AceCommandImpl) from AceCommandImpl to AceCommandImpl {
	private static function bindToAccel(b:String):String {
		return NativeString.replaceExt(b, AceMacro.jsRx(~/\b-\b/g), "+");
	}
	public function getAccelerator():String {
		var key:AceCommandKey = this.bindKey;
		if (Std.is(key, String)) return bindToAccel(key);
		var pair:AceCommandKeyPair = key;
		return bindToAccel(AceUserAgent.isMac ? pair.mac : pair.win);
	}
}
typedef AceCommandImpl = {
	?bindKey:AceCommandKey,
	exec:AceWrap->Void,
	name:String,
	?readOnly: Bool,
	?scrollIntoView:String,
	?multiSelectAction:String,
}

/** "ctrl-K" or { win:"ctrl-K", mac:"cmd-K" } */
typedef AceCommandKey = EitherType<String, AceCommandKeyPair>;
typedef AceCommandKeyPair = { win:String, mac:String };

/** command object or name of an existing command */
typedef AceCommandOrName = EitherType<AceCommand, String>;

/** command / name / function */
typedef AceCommandInit = EitherType<AceCommandOrName, Function>;
