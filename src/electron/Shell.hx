package electron;
import js.Error;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_Shell") extern class Shell {
	public static function openItem(path:String):Bool;
	public static function openExternal(url:String, ?opt:Dynamic, ?cb:Error->Void):Bool;
}
