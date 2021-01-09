package gml.project;
import electron.ConfigFile;
import electron.FileSystem;
import electron.FileWrap;
import haxe.Json;
import tools.Aliases;
import tools.Dictionary;
import gml.Project;
import Main.window;
import tools.NativeString;
import ui.Preferences;
using tools.PathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class ProjectStateManager {
	static var conf:ConfigFile<Dictionary<ProjectState>>;
	
	public static function get(path:String):ProjectState {
		path = PathTools.ptNoBS(path);
		if (FileSystem.canSync) {
			if (conf.sync()) conf.data = {};
			return conf.data[path];
		} else try {
			var stateText = window.localStorage.getItem("project:" + path);
			if (stateText == null || stateText == "") return null;
			return Json.parse(stateText);
		} catch (_:Dynamic) {
			return null;
		}
	}
	
	public static function set(path:String, state:ProjectState) {
		path = PathTools.ptNoBS(path);
		var t = Date.now().getTime();
		if (FileSystem.canSync) {
			state.mtime = t;
			conf.sync();
			conf.data[path] = state;
			conf.flush();
		} else {
			window.localStorage.setItem("project:" + path, Json.stringify(state));
			window.localStorage.setItem("@project:" + path, "" + t);
		}
	}
	
	public static function init() {
		var keepTime = (1000 * 60 * 60 * 24 * Preferences.current.projectSessionTime);
		var remTime:Float = Date.now().getTime() - keepTime;
		if (FileSystem.canSync) {
			conf = new ConfigFile("session", "project-states");
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
			var ls = window.localStorage;
			var backslashList:Array<String> = [];
			var remList:Array<String> = [];
			for (i in 0 ... ls.length) {
				var k = ls.key(i);
				if (NativeString.startsWith(k, "@project:")) {
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