package electron;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_Clipboard") extern class Clipboard {
	public function readText():String;
	public function writeText(s:String):Void;
}
