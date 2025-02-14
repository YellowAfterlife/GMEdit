package gmk;
import gmx.SfGmx;
import parsers.GmlEvent;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmkEvent {
	static var categories:Array<String> = [
		"CREATE", "DESTROY", "ALARM", "STEP", "COLLISION", "KEYBOARD",
		"MOUSE", "OTHER", "DRAW", "KEYPRESS", "KEYRELEASE", "TRIGGER",
	];
	public static function compare(a:SfGmx, b:SfGmx) {
		var aCatStr = a.get("category");
		var aCat = categories.indexOf(aCatStr);
		var bCatStr = b.get("category");
		var bCat = categories.indexOf(bCatStr);
		if (aCat != bCat) return aCat - bCat;
		//
		var aWith = a.get("with");
		var bWith = b.get("with");
		if (aWith != bWith) return aWith < bWith ? -1 : 1;
		//
		var aNumb = Std.parseInt(a.get("id"));
		var bNumb = Std.parseInt(b.get("id"));
		return aNumb - bNumb;
	}
	public static function toStringGmk(event:SfGmx) {
		var catStr = event.get("category");
		var cat = categories.indexOf(catStr);
		var obj = event.get("with");
		var numb = obj == null ? Std.parseInt(event.get("id")) : null;
		return GmlEvent.toString(cat, numb, obj);
	}
	
	public static function isEmpty(event:SfGmx):Bool {
		for (actions in event.findAll("actions")) {
			if (actions.find("action") != null) return false;
		}
		return true;
	}
	
	private static var rxHeader = ~/^\/\/\/\/?(.*)/;
	public static function getCode(event:SfGmx) {
		var actions:Array<SfGmx> = [];
		for (actionRoot in event.findAll("actions")) {
			for (action in actionRoot.findAll("action")) actions.push(action);
		}
		if (actions.length == 0) return "";
		var code = GmkAction.getCodeMulti(actions);
		return code;
	}
}