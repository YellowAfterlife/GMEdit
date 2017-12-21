package electron;
import gmx.SfGmx;
import js.Error;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_FS") extern class FileSystem {
	public static function readFile(path:String, enc:String, callback:Error->Dynamic->Void):Void;
	public static inline function readTextFile(path:String, callback:Error->String->Void):Void {
		readFile(path, "utf8", cast callback);
	}
	public static function readFileSync(path:String, ?enc:String):Dynamic;
	public static inline function readTextFileSync(path:String):String {
		return readFileSync(path, "utf8");
	}
	public static inline function readGmxFileSync(path:String):SfGmx {
		return SfGmx.parse(readTextFileSync(path));
	}
	public static function writeFileSync(path:String, data:Dynamic, ?options:Dynamic):Void;
}
