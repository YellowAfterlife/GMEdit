package;

import ace.*;
import ace.AceWrap;
import electron.*;
import electron.Dialog;
import gml.*;
import shaders.*;
import file.kind.misc.KPlain;
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
import plugins.PluginManager;
import tools.HtmlTools;
import ui.ChromeTabs;
import ui.*;
#if gmedit.live
import ui.liveweb.*;
#end
import ui.miniweb.MiniWeb;
import ui.treeview.TreeView;
import ui.treeview.TreeViewMenus;

/**
 * ...
 * @author YellowAfterlife
 */
class Main {
	//
	public static var window(get, never):Window;
	private static inline function get_window() {
		return js.Syntax.code("window");
	}
	//
	public static var console(get, never):RawConsole;
	private static inline function get_console() {
		return js.Syntax.code("console");
	}
	//
	public static var document(get, never):HTMLDocument;
	private static inline function get_document() {
		return js.Syntax.code("document");
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
	static function main():Void {
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
		yy.YyJsonPrinter.init();
		if (Electron == null) {
			document.querySelector("#app").classList.add("app-browser");
		}
		//
		modulePath = untyped window.__dirname;
		if (modulePath == null) {
			modulePath = ".";
			untyped window.__dirname = ".";
		}
		Preferences.init();
		file.FileKind.initStatic();
		file.kind.KGml.initSyntaxExtensions();
		GmlVersion.init();
		GmlAPI.init();
		ShaderAPI.init();
		GmlEvent.init();
		untyped window.ace_mode_gml_0();
		AceGmlHighlight.init();
		AceMdHighlight.init();
		AceHxHighlight.init();
		ShaderHighlight.init();
		untyped window.ace_mode_gml_1();
		editors.Editor.init();
		AceSnippets.init();
		AceWrap.init();
		CommandPalette.init();
		aceEditor = new AceWrap(document.querySelector("#source"), {
			isPrimary: true,
			dispatchEvent: false,
		});
		(window:Dynamic).aceEditor = aceEditor;
		AceCtxMenu.initMac(aceEditor);
		editors.EditCode.currentNew = cast new gml.file.GmlFile("", null, KPlain.inst, "").editor;
		KeyboardShortcuts.initGlobal();
		ColorPicker.init();
		GlobalSearch.init();
		GlobalLookup.init();
		TagEditor.init();
		Sidebar.init();
		MainMenu.init();
		//
		#if !gmedit.live
		aceEditor.session = WelcomePage.init(aceEditor);
		#end
		untyped window.ace_mode_gml_2();
		//
		AceSessionData.init();
		TreeView.init();
		TreeViewMenus.init();
		ProjectStyle.init();
		FileDrag.init();
		ChromeTabs.init();
		Project.init();
		aceEditor.statusBar.update();
		Project.nameNode.innerText = "Loading plugins...";
		plugins.PluginManager.init(function() {
			Project.nameNode.innerText = "Loading project...";
			Project.openInitialProject();
			#if gmedit.live
				aceEditor.session = WelcomePage.init(aceEditor);
				#if gmedit.mini
					MiniWeb.init();
				#else
					LiveWeb.init();
				#end
			#end
			PluginManager.dispatchInitCallbacks();
		});
		console.log("hello!");
		StartupTests.main();
	}
}
