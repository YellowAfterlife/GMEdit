package electron;
import js.lib.Error;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_Shell") extern class Shell {
	public static function openExternal(url:String, ?opt:Dynamic, ?cb:Error->Void):Bool;
	/*
	// https://github.com/electron/electron/issues/4349
	public static function openItem(path:String):Bool;
	public static function showItemInFolder(path:String):Bool;
	*/
	public static inline function openItem(path:String):Void {
		IPC.send("shell-open", path);
	}
	public static inline function showItemInFolder(path:String):Void {
		IPC.send("shell-show", path);
	}
}
