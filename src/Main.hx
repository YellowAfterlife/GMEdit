package;

import ace.*;
import ace.AceWrap;
import electron.*;
import electron.Dialog;
import gml.*;
import shaders.*;
import haxe.io.Path;
import js.Lib;
import tools.*;
import js.html.Console;
import js.html.DivElement;
import js.html.DragEvent;
import js.html.Element;
import js.html.HTMLDocument;
import js.html.KeyboardEvent;
import js.html.Window;
import parsers.GmlEvent;
import tools.HtmlTools;
import ui.ChromeTabs;
import ui.*;

/**
 * ...
 * @author YellowAfterlife
 */
class Main {
	//
	public static var window(get, never):Window;
	private static inline function get_window() {
		return untyped __js__("window");
	}
	//
	public static var console(get, never):Console;
	private static inline function get_console() {
		return untyped __js__("console");
	}
	//
	public static var document(get, never):HTMLDocument;
	private static inline function get_document() {
		return untyped __js__("document");
	}
	//
	public static var modulePath:String;
	public static inline function relPath(path:String) {
		return haxe.io.Path.join([modulePath, path]);
	}
	public static var aceEditor:AceWrap;
	public static var moduleArgs:Dictionary<String>;
	//
	private static function getArgs() {
		var out = new Dictionary<String>();
		var search = document.location.search;
		if (search != "") {
			for (pair in search.substring(1).split("&")) {
				var eq = pair.indexOf("=");
				if (eq >= 0) {
					var val = StringTools.urlDecode(pair.substring(eq + 1));
					out.set(pair.substring(0, eq), val);
				} else out.set(pair, "");
			}
		}
		return out;
	}
	//
	static function main() {
		moduleArgs = getArgs();
		haxe.Log.trace = @:access(js.Boot.__string_rec) function(
			v:Dynamic, ?infos:haxe.PosInfos
		) {
			var out:Array<Dynamic> = [v];
			if (infos != null) {
				out.unshift(infos.fileName + ":" + infos.lineNumber);
				if (infos.customParams != null) {
					for (v in infos.customParams) out.push(v);
				}
			}
			var console = window.console;
			Reflect.callMethod(console, console.log, out);
		};
		Electron.init();
		if (Electron == null) {
			document.querySelector("#app").classList.add("app-browser");
		}
		//
		modulePath = untyped window.__dirname;
		if (modulePath == null) modulePath = ".";
		Preferences.init();
		GmlAPI.init();
		ShaderAPI.init();
		GmlEvent.init();
		untyped window.ace_mode_gml_0();
		AceGmlHighlight.init();
		ShaderHighlight.init();
		untyped window.ace_mode_gml_1();
		var aceEl = document.querySelector("#source");
		var acePar = aceEl.parentElement;
		editors.Editor.init();
		aceEditor = new AceWrap(aceEl);
		AceWrap.init();
		untyped aceEditor.$blockScrolling = Infinity;
		AceStatusBar.init(aceEditor, acePar);
		AceGmlCompletion.init(aceEditor);
		KeyboardShortcuts.initGlobal();
		ColorPicker.init();
		GlobalSearch.init();
		GlobalLookup.init();
		Preferences.initEditor();
		MainMenu.init();
		//
		aceEditor.session = WelcomePage.init(aceEditor);
		KeyboardShortcuts.initEditor();
		ScrollMode.init();
		AceGmlCommands.init();
		untyped window.ace_mode_gml_2();
		//
		AceSessionData.init();
		TreeView.init();
		TreeViewMenus.init();
		ProjectStyle.init();
		FileDrag.init();
		ChromeTabs.init();
		Project.init();
		AceStatusBar.statusUpdate();
		LiveWeb.init();
		//
		try {
			Type.resolveClass("Main");
			untyped __js__("window.$hxClasses = $hxClasses");
		} catch (x:Dynamic) {
			trace("Couldn't expose hxClasses: " + x);
		}
		//
		console.log("hello!");
		return null;
	}
}
