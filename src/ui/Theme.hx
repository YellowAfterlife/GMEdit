package ui;
#if starter
import ui.Starter.FileSystemMin in FileSystem;
#else
import electron.FileSystem;
import electron.FileWrap;
#end
import haxe.io.Path;
import js.html.Element;
import js.html.HTMLDocument;

/**
 * Handles theme state and loading.
 * @author YellowAfterlife
 */
class Theme {
	//
	static var document(get, never):HTMLDocument;
	private static inline function get_document() {
		return js.Syntax.code("document");
	}
	//
	public static inline var path:String = "themes";
	private static var refElement:Element = document.getElementById("project-style");
	private static var elements:Array<Element> = (function() {
		var qry = document.querySelectorAll("link[data-is-theme]");
		var arr = [];
		for (e in qry) arr.push(cast e);
		return arr;
	})();
	private static function reset() {
		for (el in elements) {
			var par = el.parentElement;
			if (par != null) par.removeChild(el);
		}
		setDarkTabs(false);
		document.documentElement.removeAttribute("data-theme-uses-bracket-depth");
	}
	private static function setDarkTabs(z:Bool) {
		var els:Array<Element> = [for (q in document.querySelectorAll(".chrome-tabs")) cast q];
		els.push(cast document.querySelector("#main"));
		for (el in els) {
			if (z) {
				el.classList.add("chrome-tabs-dark-theme");
			} else el.classList.remove("chrome-tabs-dark-theme");
		}
	}
	private static function add(name:String, then:Void->Void):Void {
		var modulePath:String, userPath:String;
		#if starter
		modulePath = Starter.modulePath;
		userPath = Starter.userPath;
		#else
		modulePath = Main.modulePath;
		userPath = FileWrap.userPath;
		#end
		var dir = Path.join([modulePath, path, name]);
		var fullConf = Path.join([dir, "config.json"]);
		function procSelf(theme:ThemeImpl) {
			if (theme.darkChromeTabs != null) setDarkTabs(theme.darkChromeTabs);
			if (theme.windowsAccentColors) electron.WindowsAccentColors.update(true);
			if (theme.useBracketDepth != null) {
				if (theme.useBracketDepth) {
					document.documentElement.setAttribute("data-theme-uses-bracket-depth", "");
				} else {
					document.documentElement.removeAttribute("data-theme-uses-bracket-depth");
				}
				#if !starter
				ace.AceGmlHighlight.useBracketDepth = theme.useBracketDepth;
				#end
			}
			//
			if (theme.stylesheets != null) for (rel in theme.stylesheets) {
				var link = document.createLinkElement();
				link.rel = "stylesheet";
				link.href = Path.join([dir, rel]);
				link.setAttribute("data-is-theme", "");
				document.head.insertBefore(link, refElement);
				elements.push(link);
			}
			then();
		}
		function proc(theme:ThemeImpl) {
			if (theme.parentTheme != null) {
				add(theme.parentTheme, function() {
					procSelf(theme);
				});
			} else procSelf(theme);
		}
		if (FileSystem.canSync) {
			try {
				if (FileSystem.existsSync(fullConf)) {
					proc(FileSystem.readJsonFileSync(fullConf));
				} else {
					dir = userPath + "/themes/" + name;
					fullConf = dir + "/config.json";
					if (FileSystem.existsSync(fullConf)) {
						proc(FileSystem.readJsonFileSync(fullConf));
					}
				}
			} catch (x:Dynamic) {
				Console.log(x);
				then();
			}
		} else {
			FileSystem.readJsonFile(fullConf, function(err, data) {
				if (data != null) proc(data);
			});
		}
	}
	public static function set(name:String, ?cb:Void->Void) {
		if (cb == null) cb = function(){};
		document.documentElement.setAttribute("data-theme", name);
		reset();
		#if !starter
		ace.AceGmlHighlight.useBracketDepth = false;
		#end
		add(name, cb);
		return name;
	}
	
	public static var current(default, set):String = (function() {
		var s = document.documentElement.getAttribute("data-theme");
		return s != null && s != "" ? s : "default";
	})();
	private static function set_current(name:String):String {
		if (current == name) return name;
		current = name;
		set(name);
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
