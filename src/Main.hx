package;

import ace.*;
import ace.AceWrap;
import electron.*;
import electron.Dialog;
import gml.GmlAPI;
import gml.GmlFile;
import gml.Project;
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
		document.body.addEventListener("keydown", KeyboardShortcuts.handle);
		Electron.init();
		//
		modulePath = untyped __dirname;
		GmlAPI.init();
		gmx.GmxEvent.init();
		untyped window.ace_mode_gml_0();
		AceGmlHighlight.init();
		untyped window.ace_mode_gml_1();
		var aceEl = document.querySelector("#source");
		var acePar = aceEl.parentElement;
		aceEditor = new AceWrap(aceEl);
		untyped aceEditor.$blockScrolling = Infinity;
		AceStatusBar.init(aceEditor, acePar);
		AceGmlCompletion.init(aceEditor);
		//
		untyped {
			window.AceEditSession = AceWrap.require("ace/edit_session").EditSession;
			window.AceUndoManager = AceWrap.require("ace/undomanager").UndoManager;
			window.aceEditor = aceEditor;
		};
		aceEditor.session = WelcomePage.init(aceEditor);
		//
		TreeView.init();
		FileDrag.init();
		ChromeTabs.init();
		//
		var path = window.localStorage.getItem("autoload");
		if (path != null) {
			Project.current = new Project(path);
		} else Project.current = null;
		//
		trace("hi!");
		return null;
	}
}
