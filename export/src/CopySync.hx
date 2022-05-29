package ;
import sys.FileSystem;
import sys.io.File;

/**
 * ...
 * @author YellowAfterlife
 */
class CopySync {
	static function deleteFile(path:String) {
		try {
			FileSystem.deleteFile(path);
			return true;
		} catch (x:Dynamic) {
			Sys.println('Failed to delete `$path`: $x');
			return false;
		}
	}
	static function deleteDir(path:String) {
		for (rel in FileSystem.readDirectory(path)) {
			if (!deleteAuto('$path/$rel')) return false;
		}
		try {
			FileSystem.deleteDirectory(path);
			return true;
		} catch (x:Dynamic) {
			Sys.println('Failed to delete `$path`: $x');
			return false;
		}
	}
	static function deleteAuto(path:String) {
		if (FileSystem.isDirectory(path)) {
			return deleteDir(path);
		} else return deleteFile(path);
	}
	
	static function copyFile(from:String, to:String) {
		try {
			File.copy(from, to);
			return true;
		} catch (x:Dynamic) {
			Sys.println('Failed to copy `$from` to `$to`: $x');
			return false;
		}
	}
	public static function copyDir(from:String, to:String, ?fromFiles:Array<String>) {
		var found = new Map();
		if (fromFiles == null) fromFiles = FileSystem.readDirectory(from);
		for (rel in fromFiles) found[rel] = true;
		
		if (FileSystem.exists(to)) {
			if (FileSystem.isDirectory(to)) {
				for (rel in FileSystem.readDirectory(to)) {
					if (!found.exists(rel)) deleteAuto('$to/$rel');
				}
			} else {
				if (!deleteFile(to)) return false;
			}
		} else {
			FileSystem.createDirectory(to);
		}
		
		for (rel in fromFiles) copy('$from/$rel', '$to/$rel');
		return true;
	}
	public static function ensureDirectory(dir:String) {
		dir = haxe.io.Path.normalize(dir);
		var parts = dir.split("/");
		for (i in 1 ... parts.length + 1) {
			var sub = parts.slice(0, i).join("/");
			if (!FileSystem.exists(sub)) FileSystem.createDirectory(sub);
		}
	}
	public static function copy(from:String, to:String) {
		if (FileSystem.isDirectory(from)) {
			copyDir(from, to);
		} else copyFile(from, to);
	}
}