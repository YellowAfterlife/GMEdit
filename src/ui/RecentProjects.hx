package ui;
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
	public static function add(path:String) {
		var curr = get();
		curr.remove(path);
		curr.unshift(path);
		if (curr.length > 16) curr.pop();
		Main.window.localStorage.setItem(lsPath, Json.stringify(curr));
	}
	public static function show() {
		TreeView.clear();
		var el = TreeView.element;
		for (path in get()) {
			var name = Path.withoutDirectory(path);
			switch (name.toLowerCase()) {
				case "main.txt", "main.cfg": {
					name = Path.withoutDirectory(Path.directory(path));
				};
			}
			el.appendChild(TreeView.makeProject(name, path));
		}
	}
}
