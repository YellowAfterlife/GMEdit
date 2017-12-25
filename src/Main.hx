package;

import ace.*;
import ace.AceWrap;
import electron.*;
import electron.Dialog;
import gml.*;
import haxe.io.Path;
import js.Lib;
import tools.*;
import js.html.DivElement;
import js.html.DragEvent;
import js.html.Element;
import js.html.HTMLDocument;
import js.html.KeyboardEvent;
import js.html.Window;
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
	//
	static function main() {
		//
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
		//
		modulePath = untyped __dirname;
		Preferences.init();
		GmlAPI.init();
		GmlEvent.init();
		untyped window.ace_mode_gml_0();
		AceGmlHighlight.init();
		untyped window.ace_mode_gml_1();
		var aceEl = document.querySelector("#source");
		var acePar = aceEl.parentElement;
		aceEditor = new AceWrap(aceEl);
		untyped aceEditor.$blockScrolling = Infinity;
		AceStatusBar.init(aceEditor, acePar);
		AceGmlCompletion.init(aceEditor);
		KeyboardShortcuts.initGlobal();
		Preferences.initEditor();
		//
		untyped {
			window.AceEditSession = AceWrap.require("ace/edit_session").EditSession;
			window.AceUndoManager = AceWrap.require("ace/undomanager").UndoManager;
			window.aceEditor = aceEditor;
		};
		aceEditor.session = WelcomePage.init(aceEditor);
		aceEditor.on("mousedown", KeyboardShortcuts.mousedown);
		aceEditor.on("mousewheel", KeyboardShortcuts.mousewheel);
		ace.AceGmlCommands.init();
		untyped window.ace_mode_gml_2();
		//
		AceSessionData.init();
		TreeView.init();
		FileDrag.init();
		ChromeTabs.init();
		Project.init();
		//
		trace("hi!");
		return null;
	}
}
