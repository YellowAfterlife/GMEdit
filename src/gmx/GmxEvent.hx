package gmx;
import ace.AceWrap;
import electron.FileSystem;
import parsers.GmlEvent;
import haxe.ds.StringMap;
import haxe.io.Path;
import tools.Dictionary;
using tools.NativeString;

/**
 * 
 * @author YellowAfterlife
 */
class GmxEvent {
	public static function toStringGmx(event:SfGmx) {
		var type = Std.parseInt(event.get("eventtype"));
		var ename = event.get("ename");
		var numb:Int = ename == null ? Std.parseInt(event.get("enumb")) : null;
		return toString(type, numb, ename);
	}
	public static inline function toString(type:Int, numb:Int, name:String) {
		return GmlEvent.toString(type, numb, name);
	}
	public static inline function fromString(name:String):GmlEventData {
		return GmlEvent.fromString(name);
	}
	private static var rxHeader = ~/^\/\/\/\/? ?(.*)/;
	public static function isEmpty(event:SfGmx) {
		return event.find("action") == null;
	}
	public static function getCode(event:SfGmx) {
		var out:String = "";
		var actions = event.findAll("action");
		function addAction(action:SfGmx, head:Bool) {
			//if (head) out += "\n";
			var code = GmxAction.getCode(action);
			if (code == null) return false;
			if (head && !code.startsWith("#action ")) {
				var addSection = true;
				code = rxHeader.map(code, function(e:EReg) {
					out += "#section " + e.matched(1);
					addSection = false;
					return "";
				});
				if (addSection) out += "#section\n";
			}
			out += code;
			return true;
		}
		if (actions.length != 0) {
			if (!addAction(actions[0], false)) return null;
			for (i in 1 ... actions.length) {
				if (!addAction(actions[i], true)) return null;
			}
		}
		return out;
	}
}
