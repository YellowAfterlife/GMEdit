package gml;
import electron.FileWrap;
import haxe.io.Path;
import tools.Dictionary;
import tools.StringBuilder;
import gml.file.GmlFile;
import electron.FileSystem;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlObjectInfo {
	public var visible:Bool;
	public var persistent:Bool;
	public var solid:Bool;
	public var objectName:String = "";
	public var spriteName:String = "";
	public var parents:Array<String> = [];
	public var children:Array<String> = [];
	public var eventList:Array<String> = [];
	/** event name -> [parent name, child name] */
	public var eventMap:Dictionary<Array<String>> = new Dictionary();
	public function new() {
		
	}
	public function print() {
		var buf = new StringBuilder();
		buf.addFormat("// Information about object @[%s]:\n", objectName);
		buf.addFormat("// Sprite: @[%s]\n", spriteName);
		buf.addFormat("#section Parents (%d)\n", parents.length);
		for (name in parents) {
			buf.addFormat("// @[%s]\n", name);
		}
		buf.addFormat("#section Events (%d)\n", eventList.length);
		for (eid in eventList) {
			var items = eventMap[eid];
			buf.addFormat("#event %s (%d)\n", eid, items.length);
			for (item in items) {
				buf.addFormat("// @[%s]\n", item);
			}
		}
		return buf.toString();
	}
	public static function showFor(path:String, ident:String) {
		var info:GmlObjectInfo;
		if (Path.extension(path) == "gmx") {
			var obj = FileWrap.readGmxFileSync(path);
			info = gmx.GmxObject.getInfo(obj, path);
		} else if (Path.extension(path) == "yy") {
			var yy:yy.YyObject = FileWrap.readJsonFileSync(path);
			info = yy.getInfo();
		} else return;
		GmlFile.openTab(new GmlFile(
			"info: " + ident,
			null, gml.file.GmlFileKind.Normal, info.print()
		));
	}
}
