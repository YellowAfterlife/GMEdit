package tools;
import gml.GmlVersion;
import haxe.io.Path;
import js.RegExp;
using tools.PathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class PathTools {
	
	/** Extracts the directory from a path */
	public static inline function ptDir(path:String):String {
		return Path.directory(path);
	}
	
	/** Trims the directory from a path */
	public static inline function ptNoDir(path:String):String {
		return Path.withoutDirectory(path);
	}
	
	/** Extracts the extension as lowercase */
	public static inline function ptExt(path:String):String {
		return Path.extension(path).toLowerCase();
	}
	
	public static inline function ptNoExt(path:String):String {
		return Path.withoutExtension(path);
	}
	
	/** Returns file name (no directory, no extension) */
	public static inline function ptName(path:String):String {
		return path.ptNoDir().ptNoExt();
	}
	
	/** ("a/b", "c") -> "a/b/c" */
	public static var ptJoin:haxe.extern.Rest<String>->String = (
		Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			return Path.join(cast args);
		})
	);
	
	public static function ptDepth(path:String):Int {
		var dir = ptDir(path);
		dir = StringTools.replace(dir, "\\", "/");
		return dir.split("/").length;
	}
	
	public static function ptDetectProject(path:String):GmlVersion {
		switch (path.ptExt()) {
			case "yyp": return GmlVersion.v2;
			case "gmx" if (path.ptNoExt().ptExt() == "project"): return GmlVersion.v1;
			case "txt", "cfg" if (path.ptName().toLowerCase() == "main"): return GmlVersion.live;
		}
		return GmlVersion.none;
	}
}
