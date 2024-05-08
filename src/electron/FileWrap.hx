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
	static inline function impl<T>(path:String, ifFull:String->T, ifRel:Project->String->T) {
		var project = Project.current;
		var relPath = project.relPath(path);
		if (relPath != null) {
			return ifRel(project, relPath);
		} else return ifFull(path);
	}
	public static function existsSync(path:String):Bool {
		if (Path.isAbsolute(path)) {
			return FileSystem.existsSync(path);
		} else return Project.current.existsSync(path);
	}
	public static function mtimeSync(path:String):Null<Float> {
		return impl(path,
			(s) -> FileSystem.mtimeSync(s),
			(p, s) -> p.mtimeSync(s),
		);
	}
	
	public static function unlinkSync(path:String):Void {
		impl(path,
			function(pt) FileSystem.unlinkSync(path),
			function(pj, pt) pj.unlinkSync(path),
		);
	}
	
	public static function readTextFile(path:String, fn:Error->String->Void):Void {
		return impl(path,
			(pt) -> FileSystem.readTextFile(pt, fn),
			(pj, pt) -> pj.readTextFile(pt, fn)
		);
	}
	public static function readTextFileSync(path:String):String {
		return impl(path,
			(pt) -> FileSystem.readTextFileSync(pt),
			(pj, pt) -> pj.readTextFileSync(pt),
		);
	}
	public static function writeTextFileSync(path:String, text:String) {
		impl(path,
			function(pt) FileSystem.writeFileSync(pt, text),
			function(pj, pt) pj.writeTextFileSync(pt, text),
		);
	}
	public static function readJsonFileSync<T>(path:String, ?c:Class<T>):T {
		return impl(path,
			(pt) -> FileSystem.readJsonFileSync(pt),
			(pj, pt) -> pj.readJsonFileSync(pt),
		);
	}
	public static inline function writeJsonFileSync(path:String, value:Dynamic) {
		writeTextFileSync(path, NativeString.yyJson(value));
	}
	/** The difference is that YY may contain off-spec JSON */
	public static function readYyFileSync<T>(path:String, ?c:Class<T>, ?extJson:Bool):T {
		return impl(path,
			(pt) -> FileSystem.readYyFileSync(pt),
			(pj, pt) -> pj.readYyFileSync(pt),
		);
	}
	public static function writeYyFileSync<T>(path:String, value:T, ?extJson:Bool):Void {
		writeTextFileSync(path, yy.YyJson.stringify(value, extJson));
	}
	//
	public static function readGmxFileSync(path:String):SfGmx {
		return impl(path,
			(pt) -> FileSystem.readGmxFileSync(pt),
			(pj, pt) -> pj.readGmxFileSync(pt),
		);
	}
	public static function writeGmxFileSync(path:String, gmx:SfGmx) {
		impl(path,
			function(pt) FileSystem.writeFileSync(pt, gmx.toGmxString()),
			function(pj, pt) pj.writeGmxFileSync(pt, gmx),
		);
	}
	public static function mkdirSync(path:String):Void {
		impl(path,
			function(pt) FileSystem.mkdirSync(pt),
			function(pj, pt) pj.mkdirSync(pt),
		);
	}
	
	public static function readdirSync(path:String) {
		return impl(path,
			function(pt) {
				var out:Array<ProjectDirInfo> = [];
				for (rel in FileSystem.readdirSync(pt)) {
					var itemFull = Path.join([pt, rel]);
					out.push({
						fileName: rel,
						relPath: itemFull,
						fullPath: itemFull,
						isDirectory: FileSystem.statSync(itemFull).isDirectory()
					});
				}
				return out;
			},
			(pj, pt) -> pj.readdirSync(path)
		);
	}
	
	public static function openExternal(path:String):Void {
		impl(path,
			function(pt) Shell.openItem(pt),
			function(pj, pt) pj.openExternal(pt),
		);
	}
	public static function showItemInFolder(path:String) {
		impl(path,
			function(pt) Shell.showItemInFolder(pt),
			function(pj, pt) pj.showItemInFolder(pt),
		);
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
		return impl(path,
			(pt) -> FileSystem.getImageURL(pt),
			(pj, pt) -> pj.getImageURL(pt),
		);
	}
	
	public static function init() {
		
	}
}
