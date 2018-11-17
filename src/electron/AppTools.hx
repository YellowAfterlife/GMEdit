package electron;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_App") extern class AppTools {
	public static function getPath(kind:String):String;
}
