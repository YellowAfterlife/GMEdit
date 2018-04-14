package electron;
import gml.Project;
import haxe.Json;
import haxe.io.Path;

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
}
