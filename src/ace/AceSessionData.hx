package ace;
import ace.AceWrap;
import ace.extern.*;
import editors.EditCode;
import gml.file.GmlFile;
import haxe.Json;
import tools.NativeString;
using tools.PathTools;
import ui.Preferences;

/**
 * ...
 * @author YellowAfterlife
 */
class AceSessionData {
	public static function get(edit:EditCode):AceSessionDataImpl {
		var session = edit.session;
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
	public static function store(edit:EditCode) {
		var data = get(edit);
		var file = edit.file;
		Main.window.localStorage.setItem("session:" + file.path, Json.stringify(data));
		Main.window.localStorage.setItem("@session:" + file.path, "" + Date.now().getTime());
	}
	//
	public static function set(edit:EditCode, data:AceSessionDataImpl) {
		var session = edit.session;
		session.selection.fromJSON(data.selection);
		for (row in data.foldLines) session.toggleFoldWidgetRaw(row, {});
		session.setScrollLeft(data.scrollLeft);
		session.setScrollTop(data.scrollTop);
	}
	public static function restore(edit:EditCode) {
		var text = Main.window.localStorage.getItem("session:" + edit.file.path);
		if (text == null) return false;
		var data:AceSessionDataImpl = null;
		try {
			data = Json.parse(text);
		} catch (_:Dynamic) return false;
		if (data == null) return false;
		//
		set(edit, data);
		return true;
	}
	public static function init() {
		var ls = Main.window.localStorage;
		var renList:Array<String> = [];
		var remList:Array<String> = [];
		var remTime:Float = Date.now().getTime()
			- (1000 * 60 * 60 * 24 * Preferences.current.fileSessionTime);
		for (i in 0 ... ls.length) {
			var k = ls.key(i);
			if (NativeString.startsWith(k, "@session:")) {
				if (k.indexOf("\x5c") >= 0) {
					renList.push(k);
				}
				else if (Std.parseFloat(ls.getItem(k)) < remTime) {
					remList.push(k);
					remList.push(k.substring(1));
				}
			}
		}
		for (remKey in remList) ls.removeItem(remKey);
		for (renKey in renList) {
			var renKey1 = renKey.substring(1);
			var v0 = ls.getItem(renKey);
			var v1 = ls.getItem(renKey1);
			ls.removeItem(renKey);
			ls.removeItem(renKey1);
			ls.setItem(renKey.ptNoBS(), v0);
			ls.setItem(renKey1.ptNoBS(), v1);
		}
	}
}
typedef AceSessionDataImpl = {
	selection:Dynamic,
	scrollLeft:Float,
	scrollTop:Float,
	foldLines:Array<Int>,
}
