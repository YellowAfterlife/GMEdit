package ui;
import electron.FileSystem;
import electron.FileWrap;
import haxe.Json;
import haxe.io.Path;
import ui.treeview.TreeView;

/**
 * ...
 * @author YellowAfterlife
 */
class RecentProjects {
	private static function get():Array<String> {
		try {
			var curr:Array<String> = FileWrap.readConfigSync("session",  "recent-projects");
			if (!Std.is(curr, Array)) return [];
			for (i in 0 ... curr.length) {
				curr[i] = tools.PathTools.ptNoBS(curr[i]);
			}
			return curr;
		} catch (_:Dynamic) return [];
	}
	private static function set(list:Array<String>) {
		FileWrap.writeConfigSync("session",  "recent-projects", list);
	}
	public static function add(path:String) {
		var curr = get();
		curr.remove(path);
		curr.unshift(path);
		if (curr.length > Preferences.current.recentProjectCount) curr.pop();
		set(curr);
	}
	public static function remove(path:String) {
		var curr = get();
		curr.remove(path);
		set(curr);
	}
	public static function show() {
		TreeView.clear();
		var el = TreeView.element;
		if (electron.Electron != null) for (path in get()) {
			var name = Path.withoutDirectory(path);
			switch (name.toLowerCase()) {
				case "main.txt", "main.cfg": {
					name = Path.withoutDirectory(Path.directory(path));
				};
			}
			var pj = TreeView.makeProject(name, path);
			FileSystem.access(path, FileSystemAccess.Exists, function(e) {
				if (e == null) {
					var th = path + ".png";
					FileSystem.access(th, FileSystemAccess.Exists, function(e) {
						if (e == null) TreeView.setThumb(path, "file:///" + th);
					});
				} else {
					pj.setAttribute("data-missing", "true");
				}
			});
			el.appendChild(pj);
		}
	}
}
