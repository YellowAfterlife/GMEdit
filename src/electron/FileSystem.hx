package electron;
import electron.extern.NodeBuffer;
#if !starter
import gmx.SfGmx;
import haxe.Json;
import js.lib.Error;
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
			if (d != null) try {
				d = Json.parse(d);
			} catch (x:Dynamic) {
				d = null; e = x;
			}
			callback(e, d);
		});
	}
	public static inline function readGmxFile(path:String, callback:Error->SfGmx->Void):Void {
		readFile(path, "utf8", function(e:Error, d:Dynamic) {
			if (d != null) try {
				d = SfGmx.parse(d);
			} catch (x:Dynamic) {
				d = null; e = x;
			}
			callback(e, d);
		});
	}
	//
	#if 0
	@:native("readFileSync")
	public static function readFileSync_1(path:String, ?enc:String):Any;
	public static inline function readFileSync(path:String, ?enc:String):Any {
		Console.log("readFileSync", path);
		return readFileSync_1(path, enc);
	}
	#else
	public static function readFileSync(path:String, ?enc:String):Any;
	#end
	public static inline function readNodeFileSync(path:String):NodeBuffer {
		return readFileSync(path);
	}
	public static inline function readTextFileSync(path:String):String {
		return readFileSync(path, "utf8");
	}
	public static inline function readGmxFileSync(path:String):SfGmx {
		return SfGmx.parse(readTextFileSync(path));
	}
	public static inline function readJsonFileSync(path:String):Dynamic {
		return Json.parse(readTextFileSync(path));
	}
	public static inline function readYyFileSync(path:String):Dynamic {
		return yy.YyJson.parse(readTextFileSync(path));
	}
	//
	public static function writeFileSync(path:String, data:Dynamic, ?options:Dynamic):Void;
	//
	public static function access(path:String, modes:FileSystemAccess, fn:Null<Error>->Void):Void;
	//
	public static function existsSync(path:String):Bool;
	public static inline function exists(path:String, fn:Null<Error>->Void):Void {
		access(path, FileSystemAccess.Exists, fn);
	}
	//
	public static function renameSync(old:String, next:String):Void;
	//
	public static function unlinkSync(path:String):Void;
	//
	public static function mkdirSync(path:String, ?options:{?recursive: Bool, ?mode: Int}):Void;
	public static function rmdirSync(path:String, ?options:{?recursive: Bool}):Void;
	public static inline function ensureDirSync(path:String):Void {
		if (!existsSync(path)) mkdirSync(path);
	}
	//
	public static function readdir(path:String, cb:Error->Array<String>->Void):Void;
	public static function readdirSync(path:String, ?options:Dynamic):Array<String>;
	//
	@:native("copyFileSync") private static function copyFileSyncImpl(path:String, dest:String):Void;
	public static inline function copyFileSync(path:String, dest:String):Void {
		if (copyFileSyncImpl == null) {
			writeFileSync(dest, readFileSync(path));
		} else copyFileSyncImpl(path, dest);
	}
	//
	public static function stat(path:String, cb:Error->FileSystemStat->Void):Void;
	public static function statSync(path:String):FileSystemStat;
	
	/** Returns last-change time for a file, or null if operation fails */
	public static inline function mtimeSync(path:String):Null<Float> {
		return FileSystemImpl.mtimeSync(path);
	}
	//
	public static inline function getImageURL(path:String):Null<String> {
		return FileSystemImpl.getImageURL(path);
	}
}
private class FileSystemImpl {
	public static function mtimeSync(path:String):Null<Float> {
		try {
			return FileSystem.statSync(path).mtimeMs;
		} catch (x:Dynamic) return null;
	}
	public static function getImageURL(path:String):Null<String> {
		var t = mtimeSync(path);
		return t != null ? 'file:///$path?mtime=$t' : null;
	}
}
enum abstract FileSystemAccess(Int) from Int to Int {
	var Exec = 1;
	var Read = 4;
	var Write = 2;
	var Exists = 0;
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
	public var mtimeMs:Float;
	public var size:Int;
}
#end