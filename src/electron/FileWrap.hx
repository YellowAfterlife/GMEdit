package electron;
import gml.Project;
import gmx.SfGmx;
import haxe.Json;
import haxe.io.Path;
import js.Error;
import tools.NativeString;
import tools.PathTools;

/**
 * A not-so-elegant workaround for memory-only project editing.
 * Files on disk use absolute paths and map to real filesystem.
 * Files from virtual projects have relative paths and map to
 * their according virtual storage system.
 * @author YellowAfterlife
 */
class FileWrap {
	public static function existsSync(path:String):Bool {
		if (Path.isAbsolute(path)) {
			return FileSystem.existsSync(path);
		} else return Project.current.existsSync(path);
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
	
	public static var userPath:String = null;
	public static function readConfigSync<T:{}>(cat:String, name:String):T {
		var text:String = null;
		if (FileSystem.canSync) {
			var full = userPath + "/" + cat + "/" + name + ".json";
			if (FileSystem.existsSync(full)) try {
				text = FileSystem.readTextFileSync(full);
			} catch (_:Dynamic) { }
		}
		if (text == null) text = Main.window.localStorage.getItem(name);
		if (text == null) return null;
		try {
			return Json.parse(text);
		} catch (_:Dynamic) {
			return null;
		}
	}
	public static function writeConfigSync<T:{}>(cat:String, name:String, obj:T):Void {
		var text = Json.stringify(obj, null, "\t");
		if (FileSystem.canSync) {
			var full = userPath + "/" + cat + "/" + name + ".json";
			FileSystem.writeFileSync(full, text);
		} else Main.window.localStorage.setItem(name, text);
	}
	public static function init() {
		
	}
}
