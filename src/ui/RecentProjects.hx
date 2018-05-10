package ui;
import electron.FileSystem;
import haxe.Json;
import haxe.io.Path;

/**
 * ...
 * @author YellowAfterlife
 */
class RecentProjects {
	private static inline var lsPath:String = "recent-projects";
	private static function get():Array<String> {
		try {
			var text = Main.window.localStorage.getItem(lsPath);
			if (text == null) return [];
			var curr = Json.parse(text);
			return Std.is(curr, Array) ? curr : [];
		} catch (_:Dynamic) return [];
	}
	private static function set(list:Array<String>) {
		Main.window.localStorage.setItem(lsPath, Json.stringify(list));
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
			if (FileSystem.existsSync(path)) {
				var th = path + ".png";
				if (FileSystem.existsSync(th)) {
					TreeView.setThumb(path, "file:///" + th);
				}
			} else {
				pj.setAttribute("data-missing", "true");
			}
			el.appendChild(pj);
		}
	}
}
