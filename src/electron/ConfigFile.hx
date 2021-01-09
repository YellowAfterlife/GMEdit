package electron;
import electron.FileWrap;
import electron.FileSystem;

/**
 * A small wrapper for keeping configuration files in sync.
 * @author YellowAfterlife
 */
@:keep class ConfigFile<T> {
	var cat:String;
	var name:String;
	var path:String;
	var mtime:Float = null;
	public var data:T;
	public function new(cat:String, name:String) {
		this.cat = cat;
		this.name = name;
		path = FileWrap.getConfigPath(cat, name);
	}
	public function sync(?force:Bool):Bool {
		var t = FileWrap.getConfigTime(cat, name);
		if (mtime < t || (t == null && mtime == null) || force) {
			mtime = t;
			data = FileWrap.readConfigSync(cat, name);
			if (data == js.Lib.undefined) return true;
		}
		return false;
	}
	public function flush() {
		FileWrap.writeConfigSync(cat, name, data);
		mtime = FileWrap.getConfigTime(cat, name);
	}
}