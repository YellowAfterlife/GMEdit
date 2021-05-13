package electron;
import electron.FileSystem;
import gml.Project;
import gmx.SfGmx;
import haxe.Json;
import haxe.io.Path;
import js.lib.Error;
import tools.Aliases;
import tools.NativeString;
import tools.PathTools;

/**
 * A not-so-elegant workaround for memory-only project editing.
 * Files on disk use absolute paths and map to real filesystem.
 * Files from virtual projects have relative paths and map to
 * their according virtual storage system.
 * @author YellowAfterlife
 */
@:keep class FileWrap {
	public static function existsSync(path:String):Bool {
		if (Path.isAbsolute(path)) {
			return FileSystem.existsSync(path);
		} else return Project.current.existsSync(path);
	}
	public static function mtimeSync(path:String):Null<Float> {
		if (Path.isAbsolute(path)) {
			return FileSystem.mtimeSync(path);
		} else return Project.current.mtimeSync(path);
	}
	
	public static function unlinkSync(path:String):Void {
		if (Path.isAbsolute(path)) {
			FileSystem.unlinkSync(path);
		} else Project.current.unlinkSync(path);
	}
	
	public static function readTextFile(path:String, fn:Error->String->Void):Void {
		if (Path.isAbsolute(path)) {
			return FileSystem.readTextFile(path, fn);
		} else return Project.current.readTextFile(path, fn);
	}
	public static function readTextFileSync(path:String):String {
		if (Path.isAbsolute(path)) {
			return FileSystem.readTextFileSync(path);
		} else return Project.current.readTextFileSync(path);
	}
	public static function writeTextFileSync(path:String, text:String) {
		if (Path.isAbsolute(path)) {
			FileSystem.writeFileSync(path, text);
		} else Project.current.writeTextFileSync(path, text);
	}
	public static function readJsonFileSync<T>(path:String, ?c:Class<T>):T {
		if (Path.isAbsolute(path)) {
			return FileSystem.readJsonFileSync(path);
		} else return Project.current.readJsonFileSync(path);
	}
	public static inline function writeJsonFileSync(path:String, value:Dynamic) {
		writeTextFileSync(path, NativeString.yyJson(value));
	}
	/** The difference is that YY may contain off-spec JSON */
	public static function readYyFileSync<T>(path:String, ?c:Class<T>):T {
		if (Path.isAbsolute(path)) {
			return FileSystem.readYyFileSync(path);
		} else return Project.current.readYyFileSync(path);
	}
	public static function writeYyFileSync<T>(path:String, value:T):Void {
		writeTextFileSync(path, yy.YyJson.stringify(value));
	}
	//
	public static function readGmxFileSync(path:String):SfGmx {
		if (Path.isAbsolute(path)) {
			return FileSystem.readGmxFileSync(path);
		} else return Project.current.readGmxFileSync(path);
	}
	public static function mkdirSync(path:String):Void {
		if (Path.isAbsolute(path)) {
			FileSystem.mkdirSync(path);
		} else Project.current.mkdirSync(path);
	}
	
	public static function readdirSync(path:String) {
		if (Path.isAbsolute(path)) {
			var out:Array<ProjectDirInfo> = [];
			for (rel in FileSystem.readdirSync(path)) {
				var itemFull = Path.join([path, rel]);
				out.push({
					fileName: rel,
					relPath: itemFull,
					fullPath: itemFull,
					isDirectory: FileSystem.statSync(itemFull).isDirectory()
				});
			}
			return out;
		} else return Project.current.readdirSync(path);
	}
	
	public static function openExternal(path:String):Void {
		if (Path.isAbsolute(path)) {
			Shell.openItem(path);
		} else Project.current.openExternal(path);
	}
	public static function showItemInFolder(path:String) {
		if (Path.isAbsolute(path)) {
			Shell.showItemInFolder(path);
		} else Project.current.showItemInFolder(path);
	}
	
	public static var isMac:Bool = false;
	public static var isUnix:Bool = false;
	public static var isWindows(get, never):Bool;
	private static inline function get_isWindows() return !isUnix;
	
	public static var userPath:String = null;
	
	//{ Configuration file helpers
	public static function getConfigPath(cat:String, name:String):FullPath {
		if (FileSystem.canSync) {
			return userPath + "/" + cat + "/" + name + ".json";
		} else return cat + "/" + name;
	}
	/**
	 * Returns mtime for the given config file, or null if it doesn't exist
	 */
	public static function getConfigTime(cat:String, name:String):Null<Float> {
		if (FileSystem.canSync) {
			return FileSystem.mtimeSync(getConfigPath(cat, name));
		} else return null;
	}
	
	/**
	 * Reads a JSON file from
	 * $userPath/$cat/$name.json (native)
	 * or localStorage[$name] (web)
	 * Returns `undefined` if the file is missing or JSON data is malformed.
	 */
	public static function readConfigSync<T>(cat:String, name:String):T {
		var path = getConfigPath(cat, name);
		var text:String;
		var def = js.Lib.undefined;
		if (FileSystem.canSync) {
			if (FileSystem.existsSync(path)) {
				try {
					text = FileSystem.readTextFileSync(path);
				} catch (_:Dynamic) return def;
			} else return def;
		} else {
			text = js.Browser.window.localStorage.getItem(path);
		}
		if (text == null) return def;
		try {
			return Json.parse(text);
		} catch (_:Dynamic) {
			return def;
		}
	}
	
	public static function writeConfigSync<T>(cat:String, name:String, obj:T):Void {
		var path = getConfigPath(cat, name);
		if (FileSystem.canSync) {
			var text = Json.stringify(obj, null, "\t");
			FileSystem.writeFileSync(path, text);
		} else {
			var text = Json.stringify(obj);
			js.Browser.window.localStorage.setItem(path, text);
		}
	}
	//}
	
	public static function getImageURL(path:String):Null<String> {
		if (Path.isAbsolute(path)) {
			return FileSystem.getImageURL(path);
		} else return Project.current.getImageURL(path);
	}
	
	public static function init() {
		
	}
}
