package ace;
import ace.AceWrap;
import ace.extern.*;
import editors.EditCode;
import electron.ConfigFile;
import electron.FileSystem;
import electron.FileWrap;
import gml.file.GmlFile;
import haxe.Json;
import tools.NativeString;
import tools.Aliases;
import tools.Dictionary;
using tools.PathTools;
import ui.Preferences;

/**
 * Handles Ace session management (remembering selection, folds, scroll when re-opening a file).
 * This is a very confusing place in terms of what every function does.
 * @author YellowAfterlife
 */
class AceSessionData {
	static var conf:ConfigFile<Dictionary<AceSessionDataImpl>>;
	
	/**
	 * Grabs session data for the given editor session.
	 */
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
	
	/**
	 * Applies session data to the given editor session, updating selection/scroll/folds.
	 */
	public static function set(edit:EditCode, data:AceSessionDataImpl) {
		var session = edit.session;
		session.selection.fromJSON(data.selection);
		for (row in data.foldLines) try {
			session.toggleFoldWidgetRaw(row, {});
		} catch (_:Dynamic) {};
		session.setScrollLeft(data.scrollLeft);
		session.setScrollTop(data.scrollTop);
	}
	
	/**
	 * 
	 */
	public static function store(edit:EditCode) {
		var data = get(edit);
		var file = edit.file;
		var t = Date.now().getTime();
		if (FileSystem.canSync) {
			data.mtime = t;
			conf.sync();
			conf.data[file.path] = data;
			conf.flush();
		} else {
			Main.window.localStorage.setItem("session:" + file.path, Json.stringify(data));
			Main.window.localStorage.setItem("@session:" + file.path, "" + t);
		}
	}
	
	/**
	 * 
	 */
	public static function restore(edit:EditCode) {
		var data:AceSessionDataImpl;
		if (FileSystem.canSync) {
			if (conf.sync()) conf.data = {};
			data = conf.data[edit.file.path];
		} else {
			var text = Main.window.localStorage.getItem("session:" + edit.file.path);
			if (text == null) return false;
			try {
				data = Json.parse(text);
			} catch (_:Dynamic) return false;
		}
		if (data == null) return false;
		//
		set(edit, data);
		return true;
	}
	
	public static function init() {
		var keepTime = (1000 * 60 * 60 * 24 * Preferences.current.fileSessionTime);
		var remTime:Float = Date.now().getTime() - keepTime;
		if (FileSystem.canSync) {
			conf = new ConfigFile("session", "ace-states");
			var changed:Bool;
			if (conf.sync(true)) {
				conf.data = {};
				changed = true;
			} else {
				var remList:Array<String> = [];
				for (k => v in conf.data) {
					if (v.mtime < remTime) remList.push(k);
				}
				changed = remList.length > 0;
				for (k in remList) conf.data.remove(k);
			}
			if (changed) conf.flush();
		} else {
			var ls = Main.window.localStorage;
			var remList:Array<String> = [];
			for (i in 0 ... ls.length) {
				var k = ls.key(i);
				if (NativeString.startsWith(k, "@session:")) {
					if (Std.parseFloat(ls.getItem(k)) < remTime) {
						remList.push(k);
						remList.push(k.substring(1));
					}
				}
			}
			for (remKey in remList) ls.removeItem(remKey);
		}
	}
}
typedef AceSessionDataImpl = {
	selection:Dynamic,
	scrollLeft:Float,
	scrollTop:Float,
	foldLines:Array<Int>,
	?mtime:Float,
}
