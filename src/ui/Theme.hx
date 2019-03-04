package ui;
import electron.FileSystem;
import electron.FileWrap;
import haxe.io.Path;
import js.html.Element;
import Main.document;
using tools.HtmlTools;

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
		var els = [for (q in document.querySelectorEls(".chrome-tabs")) q];
		els.push(document.querySelectorAuto("#main"));
		for (el in els) {
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
				link.href = Path.join([dir, rel]);
				Main.document.head.appendChild(link);
				elements.push(link);
			}
		}
		if (FileSystem.canSync) {
			if (FileSystem.existsSync(fullConf)) {
				proc(FileSystem.readJsonFileSync(fullConf));
			} else {
				dir = FileWrap.userPath + "/themes/" + name;
				fullConf = dir + "/config.json";
				if (FileSystem.existsSync(fullConf)) {
					proc(FileSystem.readJsonFileSync(fullConf));
				}
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
