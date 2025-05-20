package electron;
import js.Browser.document;
import js.html.Console;
#if starter
import ui.Starter.ElectronMin in Electron;
#end
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
			inline function req(path:String):Dynamic {
				return (cast js.Browser.window).require(path);
			}
			// https://discuss.atom.io/t/require-javascript-file-in-renderer-process/37343/8
			var remote = Electron.remote;
			if (remote == null) remote = req("@electron/remote");
			var path = req("path");
			#if starter
			var appPath = remote.app.getAppPath();
			#else
			var appPath = electron.AppTools.getAppPath();
			#end
			var jsPath = path.resolve(appPath, "./misc/WindowsAccentColors.js");
			impl = req(jsPath);
		} catch (x:Dynamic) {
			Console.error("Error initializing accent colors: ", x);
		}
	}
	public static function updateFocus(active:Bool) {
		init();
		if (impl == null) return;
		var html = document.documentElement;
		var style = html.style;
		var pre = active ? "active" : "inactive";
		html.setAttribute("titlebar-foreground-is-light",
			html.getAttribute(pre + "-titlebar-foreground-is-light"));
		style.setProperty("--titlebar-background-color",
			style.getPropertyValue('--$pre-titlebar-background-color'));
		style.setProperty("--titlebar-foreground-color",
			style.getPropertyValue('--$pre-titlebar-foreground-color'));
	}
	public static function update(?focus:Bool) {
		if (impl == null) {
			init();
		} else impl.reload();
		if (impl == null) return;
		if (!impl.isDetectable) return;
		var fc0 = impl.inactiveTitlebarTextColor;
		var fc1 = impl.titlebarTextColor;
		var html = document.documentElement;
		//Console.log(fc0, fc1);
		html.setAttribute("hasAccentColors", "");
		html.setAttribute("active-titlebar-foreground-is-light", "" + (fc1 == "#ffffff"));
		html.setAttribute("inactive-titlebar-foreground-is-light", "" + (fc0 == "#ffffff"));
		
		var style = html.style;
		style.setProperty("--active-titlebar-background-color", impl.titlebarColor);
		style.setProperty("--active-titlebar-foreground-color", fc1);
		style.setProperty("--inactive-titlebar-background-color", impl.inactiveTitlebarColor);
		style.setProperty("--inactive-titlebar-foreground-color", fc0);
		
		if (focus == null) focus = document.documentElement.hasAttribute("hasFocus");
		updateFocus(focus);
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
