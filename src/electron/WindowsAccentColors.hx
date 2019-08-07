package electron;
/**
 * ...
 * @author YellowAfterlife
 */

class WindowsAccentColors {
	static var ready = false;
	static var impl:WindowsAccentColorsImpl = null;
	public static function init() {
		if (ready) return;
		ready = true;
		try {
			if (Electron == null) return;
			if (untyped (window.process.platform) != "win32") return;
			untyped {
				// https://discuss.atom.io/t/require-javascript-file-in-renderer-process/37343/8
				var remote = Electron.remote;
				var path = require("path");
				var appPath = remote.app.getAppPath();
				var jsPath = path.resolve(appPath, "./misc/WindowsAccentColors.js");
				impl = require(jsPath);
			};
		} catch (x:Dynamic) {
			Main.console.log("Error initializing accent colors: ", x);
		}
	}
	public static function updateFocus(active:Bool) {
		if (impl == null) return;
		var html = Main.document.documentElement;
		var style = html.style;
		var pre = active ? "active" : "inactive";
		html.setAttribute("titlebar-foreground-is-light",
			html.getAttribute(pre + "-titlebar-foreground-is-light"));
		style.setProperty("--titlebar-background-color",
			style.getPropertyValue('--$pre-titlebar-background-color'));
		style.setProperty("--titlebar-foreground-color",
			style.getPropertyValue('--$pre-titlebar-foreground-color'));
	}
	public static function update() {
		if (impl == null) {
			init();
		} else impl.reload();
		if (impl == null) return;
		if (!impl.isDetectable) return;
		var fc0 = impl.inactiveTitlebarTextColor;
		var fc1 = impl.titlebarTextColor;
		var html = Main.document.documentElement;
		//Main.console.log(fc0, fc1);
		html.setAttribute("hasAccentColors", "");
		html.setAttribute("active-titlebar-foreground-is-light", "" + (fc1 == "#ffffff"));
		html.setAttribute("inactive-titlebar-foreground-is-light", "" + (fc0 == "#ffffff"));
		
		var style = html.style;
		style.setProperty("--active-titlebar-background-color", impl.titlebarColor);
		style.setProperty("--active-titlebar-foreground-color", fc1);
		style.setProperty("--inactive-titlebar-background-color", impl.inactiveTitlebarColor);
		style.setProperty("--inactive-titlebar-foreground-color", fc0);
		
		updateFocus(Main.document.documentElement.hasAttribute("hasFocus"));
	}
}
extern class WindowsAccentColorsImpl {
	var isDetectable:Bool;
	var isSupported:Bool;
	var titlebarColor:String;
	var titlebarTextColor:String;
	var inactiveTitlebarColor:String;
	var inactiveTitlebarTextColor:String;
	function reload():Void;
}
