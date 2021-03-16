package yy.zip;
using tools.PathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class YyZipBase {
	/** relative to zip root, forward slashes only! */
	public var path(default, null):String;
	/** path without extension */
	public var fname(default, null):String;
	/** directory */
	public var dir(default, null):String;
	public function new(_path:String) {
		inline setPath(_path);
	}
	public function rename(_fname:String) {
		fname = _fname;
		path = dir + "/" + _fname;
	}
	public function setPath(_path:String) {
		path = _path;
		fname = _path.ptNoDir();
		dir = _path.ptDir();
	}
	public function trimStart(len:Int) {
		path = path.substring(len);
		dir = dir.substring(len);
	}
}