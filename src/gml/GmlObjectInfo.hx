package gml;
import electron.FileWrap;
import file.kind.gml.KGmlScript;
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
	public var eventList:Array<String> = [];
	public var depth:Float = null;
	/** event name -> [parent name, child name] */
	public var eventMap:Dictionary<Array<String>> = new Dictionary();
	public function new() {
		
	}
	public function print() {
		var buf = new StringBuilder();
		buf.addFormat("// Information about object @[%s]:\n", objectName);
		buf.addFormat("// Sprite: @[%s]\n", spriteName);
		buf.addFormat("// Visible: %s\n", "" + visible);
		buf.addFormat("// Soild: %s\n", "" + solid);
		buf.addFormat("// Persistent: %s\n", "" + persistent);
		if (depth != null) buf.addFormat("// Depth: %s\n", "" + depth);
		buf.addFormat("#section Parents (%d)\n", parents.length);
		for (name in parents) {
			buf.addFormat("// @[%s]\n", name);
		}
		var children = Project.current.objectChildren[objectName];
		var childCount = children != null ? children.length : 0;
		if (childCount > 0) {
			var cbuf = new StringBuilder();
			function childCountRec(name:String, depth:Int) {
				if (++depth > 64) return 0;
				var found = 0;
				var arr = Project.current.objectChildren[name];
				if (arr != null) {
					found += arr.length;
					for (child in arr) found += childCountRec(child, depth);
				}
				return found;
			}
			for (child in children) {
				cbuf.addFormat('// @[%s]', child);
				var subCount = childCountRec(child, 0);
				if (subCount > 0) {
					cbuf.addFormat(' (%d child%s)', subCount, subCount != 1 ? "ren" : "");
					childCount += subCount;
				}
				cbuf.addString('\n');
			}
			buf.addFormat("#section Children (%d)\n", childCount);
			buf.addString(cbuf.toString());
		} else buf.addFormat("#section Children (0)\n");
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
			null, KGmlScript.inst, info.print()
		));
	}
}
