package gmx;
import tools.JsTools;
import ace.AceWrap;
import gmx.GmxAction;
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
	public static function isEmpty(event:SfGmx) {
		return event.find("action") == null;
	}
	
	private static var rxHeader = ~/^\/\/\/\/?(.*)/;
	private static var rxHashStart = JsTools.rx(~/^#(?:action|with)\b/);
	public static function getCode(event:SfGmx) {
		var out:String = "";
		var actions = event.findAll("action");
		function addAction(action:SfGmx, head:Bool) {
			//if (head) out += "\n";
			var code = GmxAction.getCode(action);
			if (code == null) return false;
			if (head && !rxHashStart.test(code)) {
				var addSection = true;
				code = rxHeader.map(code, function(e:EReg) {
					var cap = e.matched(1);
					out += "#section";
					if (cap.charCodeAt(0) != " ".code) out += "|";
					out += cap;
					addSection = false;
					return "";
				});
				if (addSection) out += "#section\n";
			}
			out += code;
			return true;
		}
		for (i => action in actions) {
			if (!addAction(action, i > 0)) {
				GmxAction.errorText = "[action " + (i + 1) + "/" + actions.length + "] " + GmxAction.errorText;
				return null;
			}
		}
		return out;
	}
}
