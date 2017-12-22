package gmx;
import electron.FileSystem;
import haxe.ds.StringMap;
import haxe.io.Path;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxEvent {
	static var t2s:Array<String> = [];
	static var s2t:Dictionary<Int> = new Dictionary();
	static var i2s:Array<Array<String>> = [];
	static var s2i:Dictionary<GmxEventData> = new Dictionary();
	public static inline function exists(name:String):Bool {
		return s2i.exists(name);
	}
	//
	static function link(type:Int, numb:Int, name:String) {
		var arr = i2s[type];
		if (arr == null) {
			arr = [];
			i2s[type] = arr;
		}
		arr[numb] = name;
		s2i.set(name, { type: type, numb: numb });
	}
	static function linkType(type:Int, name:String) {
		t2s[type] = name;
		s2t.set(name, type);
	}
	//
	public static function toString(type:Int, numb:Int, name:String) {
		if (type == 4) {
			return "collision:" + name;
		}
		var arr = i2s[type];
		if (arr != null) {
			var out = arr[numb];
			if (out != null) return out;
		}
		var tName = t2s[type];
		if (tName != null) return tName + ":" + numb;
		return "event" + type + ":" + numb;
	}
	public static function fromString(name:String):GmxEventData {
		var out = s2i.get(name);
		if (out != null) return out;
		var i = name.indexOf(":");
		if (i < 0) return null;
		var type = s2t[name.substring(0, i)];
		if (type == null) return null;
		if (type == 4) return { type: type, numb: null, name: name.substring(i + 1) };
		var numb = Std.parseInt(name.substring(i + 1));
		if (numb == null) return null;
		return { type: type, numb: numb };
	}
	//
	public static function init() {
		for (i in 0 ... 16) linkType(i, "event" + i);
		linkType(0, "create");
		linkType(1, "destroy");
		linkType(2, "alarm");
		linkType(3, "step");
		linkType(4, "collision");
		linkType(5, "keyboard");
		linkType(6, "mouse");
		linkType(7, "other");
		linkType(8, "draw");
		linkType(9, "keypress");
		linkType(10, "keyrelease");
		var data = FileSystem.readFileSync(Main.relPath("api/events.gml"), "utf8");
		tools.ERegTools.each(~/^(\d+):(\d+)[ \t]+(\w+)/gm, data, function(rx:EReg) {
			link(Std.parseInt(rx.matched(1)), Std.parseInt(rx.matched(2)), rx.matched(3));
		});
	}
}
typedef GmxEventData = { type:Int, numb:Int, ?name:String };
