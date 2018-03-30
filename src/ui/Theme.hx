package ui;
import electron.FileSystem;
import haxe.io.Path;
import js.html.Element;
import Main.document;

/**
 * ...
 * @author YellowAfterlife
 */
class Theme {
	public static inline var path:String = "themes";
	private static var elements:Array<Element> = [];
	private static function reset() {
		for (el in elements) {
			var par = el.parentElement;
			if (par != null) par.removeChild(el);
		}
		setDarkTabs(false);
	}
	private static function setDarkTabs(z:Bool) {
		var c = "chrome-tabs-dark-theme";
		for (node in document.querySelectorAll(".chrome-tabs")) {
			var el:Element = cast node;
			var cl = el.classList;
			if (z) cl.add(c); else cl.remove(c);
		}
	}
	private static function add(name:String):Void {
		var dir = Path.join([Main.modulePath, path, name]);
		var fullConf = Path.join([dir, "config.json"]);
		function proc(theme:ThemeImpl) {
			if (theme.parentTheme != null) add(theme.parentTheme);
			if (theme.darkChromeTabs != null) setDarkTabs(theme.darkChromeTabs);
			//
			if (theme.stylesheets != null) for (rel in theme.stylesheets) {
				var link = Main.document.createLinkElement();
				link.rel = "stylesheet";
				link.href = Path.join([path, name, rel]);
				Main.document.head.appendChild(link);
				elements.push(link);
			}
		}
		if (FileSystem.canSync) {
			if (FileSystem.existsSync(fullConf)) {
				proc(FileSystem.readJsonFileSync(fullConf));
			}
		} else {
			FileSystem.readJsonFile(fullConf, function(err, data) {
				if (data != null) proc(data);
			});
		}
	}
	public static var current(default, set):String = "default";
	private static function set_current(name:String):String {
		if (current == name) return name;
		current = name;
		reset();
		add(name);
		return name;
	}
}
typedef ThemeImpl = {
	?parentTheme:String,
	?stylesheets:Array<String>,
	?darkChromeTabs:Bool,
}
