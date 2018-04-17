package electron;
import gml.Project;
import gmx.SfGmx;
import haxe.Json;
import haxe.io.Path;
import js.Error;

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
}
