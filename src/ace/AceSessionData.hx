package ace;
import ace.AceWrap;
import gml.file.GmlFile;
import haxe.Json;
import tools.NativeString;
import ui.Preferences;

/**
 * ...
 * @author YellowAfterlife
 */
class AceSessionData {
	public static function get(file:GmlFile):AceSessionDataImpl {
		var session = file.session;
		//
		var foldLines:Array<Int> = [];
		function getFoldsRec(out:Array<Int>, fold:AceFold, ofs:Int):Void {
			var row = ofs + fold.start.row;
			var children = fold.subFolds;
			var i = children.length;
			while (--i >= 0) getFoldsRec(out, children[i], row);
			out.push(row);
		}
		for (fold in session.getAllFolds()) getFoldsRec(foldLines, fold, 0);
		//
		return {
			selection: session.selection.toJSON(),
			scrollLeft: session.getScrollLeft(),
			scrollTop: session.getScrollTop(),
			foldLines: foldLines,
		};
	}
	public static function store(file:GmlFile) {
		var data = get(file);
		Main.window.localStorage.setItem("session:" + file.path, Json.stringify(data));
		Main.window.localStorage.setItem("@session:" + file.path, "" + Date.now().getTime());
	}
	//
	public static function set(file:GmlFile, data:AceSessionDataImpl) {
		var session = file.session;
		session.selection.fromJSON(data.selection);
		for (row in data.foldLines) session.toggleFoldWidgetRaw(row, {});
		session.setScrollLeft(data.scrollLeft);
		session.setScrollTop(data.scrollTop);
	}
	public static function restore(file:GmlFile) {
		var text = Main.window.localStorage.getItem("session:" + file.path);
		if (text == null) return false;
		var data:AceSessionDataImpl = null;
		try {
			data = Json.parse(text);
		} catch (_:Dynamic) return false;
		if (data == null) return false;
		//
		set(file, data);
		return true;
	}
	public static function init() {
		var ls = Main.window.localStorage;
		var remList:Array<String> = [];
		var remTime:Float = Date.now().getTime()
			- (1000 * 60 * 60 * 24 * Preferences.current.fileSessionTime);
		for (i in 0 ... ls.length) {
			var k = ls.key(i);
			if (NativeString.startsWith(k, "@session:")) {
				var t = Std.parseFloat(ls.getItem(k));
				if (Std.parseFloat(ls.getItem(k)) < remTime) {
					remList.push(k);
					remList.push(k.substring(1));
				}
			}
		}
		for (remKey in remList) ls.removeItem(remKey);
	}
}
typedef AceSessionDataImpl = {
	selection:Dynamic,
	scrollLeft:Float,
	scrollTop:Float,
	foldLines:Array<Int>,
}
