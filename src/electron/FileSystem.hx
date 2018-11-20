package electron;
import gmx.SfGmx;
import haxe.Json;
import js.Error;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_FS") extern class FileSystem {
	/** Whether synchronous functions are supported */
	public static var canSync(get, never):Bool;
	private static inline function get_canSync():Bool {
		return existsSync != null;
	}
	//
	public static function readFile(path:String, enc:String, callback:Error->Dynamic->Void):Void;
	public static inline function readTextFile(path:String, callback:Error->String->Void):Void {
		readFile(path, "utf8", cast callback);
	}
	public static inline function readJsonFile<T:{}>(path:String, callback:Error->T->Void):Void {
		readFile(path, "utf8", function(e:Error, d:Dynamic) {
			callback(e, d != null ? Json.parse(d) : null);
		});
	}
	public static inline function readGmxFile(path:String, callback:Error->SfGmx->Void):Void {
		readFile(path, "utf8", function(e:Error, d:Dynamic) {
			callback(e, d != null ? SfGmx.parse(d) : null);
		});
	}
	//
	public static function readFileSync(path:String, ?enc:String):Dynamic;
	public static inline function readTextFileSync(path:String):String {
		return readFileSync(path, "utf8");
	}
	public static inline function readGmxFileSync(path:String):SfGmx {
		return SfGmx.parse(readTextFileSync(path));
	}
	public static inline function readJsonFileSync(path:String):Dynamic {
		return Json.parse(readTextFileSync(path));
	}
	//
	public static function writeFileSync(path:String, data:Dynamic, ?options:Dynamic):Void;
	//
	public static function existsSync(path:String):Bool;
	//
	public static function renameSync(old:String, next:String):Void;
	//
	public static function unlinkSync(path:String):Void;
	//
	public static function mkdirSync(path:String, ?mode:Int):Void;
	public static function rmdirSync(path:String):Void;
	public static inline function ensureDirSync(path:String):Void {
		if (!existsSync(path)) mkdirSync(path);
	}
	//
	public static function readdirSync(path:String, ?options:Dynamic):Array<String>;
	//
	@:native("copyFileSync") private static function copyFileSyncImpl(path:String, dest:String):Void;
	public static inline function copyFileSync(path:String, dest:String):Void {
		if (copyFileSyncImpl == null) {
			writeFileSync(dest, readFileSync(path));
		} else copyFileSyncImpl(path, dest);
	}
	//
	public static function statSync(path:String):FileSystemStat;
	public static inline function getMTimeMs(path:String):Float {
		return statSync(path).mtimeMs;
	}
}
@:keep class FileSystemBrowser {
	static function readFile(path:String, enc:String, callback:Error->Dynamic->Void):Void {
		var http = new haxe.http.HttpJs(path);
		http.onError = function(msg) callback(new Error(msg), null);
		http.onData = function(data) callback(null, data);
		http.request();
	}
}
extern class FileSystemStat {
	public function isFile():Bool;
	public function isDirectory():Bool;
	public var atime:Date;
	public var mtime:Date;
	public var ctime:Date;
	public var mtimeMs(get, never):Float;
	private inline function get_mtimeMs():Float {
		return mtime.getTime();
	}
	public var size:Int;
}
