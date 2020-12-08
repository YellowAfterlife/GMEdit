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
	private static var refElement:Element = document.getElementById("project-style");
	private static var elements:Array<Element> = [];
	private static function reset() {
		for (el in elements) {
			var par = el.parentElement;
			if (par != null) par.removeChild(el);
		}
		setDarkTabs(false);
	}
	private static function setDarkTabs(z:Bool) {
		var els = [for (q in document.querySelectorEls(".chrome-tabs")) q];
		els.push(document.querySelectorAuto("#main"));
		for (el in els) el.classList.setTokenFlag("chrome-tabs-dark-theme", z);
	}
	private static function add(name:String):Void {
		var dir = Path.join([Main.modulePath, path, name]);
		var fullConf = Path.join([dir, "config.json"]);
		function proc(theme:ThemeImpl) {
			if (theme.parentTheme != null) add(theme.parentTheme);
			if (theme.darkChromeTabs != null) setDarkTabs(theme.darkChromeTabs);
			if (theme.windowsAccentColors) electron.WindowsAccentColors.update();
			if (theme.useBracketDepth != null) {
				ace.AceGmlHighlight.useBracketDepth = theme.useBracketDepth;
			}
			//
			if (theme.stylesheets != null) for (rel in theme.stylesheets) {
				var link = Main.document.createLinkElement();
				link.rel = "stylesheet";
				link.href = Path.join([dir, rel]);
				Main.document.head.insertBeforeEl(link, refElement);
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
		document.documentElement.setAttribute("data-theme", name);
		current = name;
		reset();
		ace.AceGmlHighlight.useBracketDepth = false;
		add(name);
		return name;
	}
}
typedef ThemeImpl = {
	?parentTheme:String,
	?stylesheets:Array<String>,
	?darkChromeTabs:Bool,
	?windowsAccentColors:Bool,
	?useBracketDepth:Bool,
}
