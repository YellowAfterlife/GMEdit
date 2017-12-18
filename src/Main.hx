package;

import ace.*;
import ace.AceWrap;
import js.Lib;
import tools.*;
import js.html.DivElement;
import js.html.Element;
import js.html.HTMLDocument;
import js.html.KeyboardEvent;
import js.html.Window;
import tools.HtmlTools;

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
	public static var chromeTabs:ChromeTabs;
	public static var project:Project;
	public static var treeview:DivElement = cast document.querySelector(".treeview");
	public static var nodefs:NodeFS = untyped require("fs");
	public static var aceEditor:AceWrap = untyped window.editor;
	//
	static function main() {
		document.body.addEventListener("keydown", KeyboardShortcuts.handle);
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
		aceEditor.on("input", function() {
			var q = GmlFile.current;
			if (q != null) {
				var changed = !aceEditor.getSession().getUndoManager().isClean();
				q.changed = changed;
			}
		});
		//
		var tabsEl = document.querySelector("#tabs");
		chromeTabs = new ChromeTabs();
		chromeTabs.init(tabsEl, {
			tabOverlapDistance: 14, minWidth: 45, maxWidth: 160
		});
		tabsEl.addEventListener("activeTabChange", function(event:Dynamic) {
			var detail = event.detail; if (detail == null) return;
			var tabEl:TreeViewItem = detail.tabEl; if (tabEl == null) return;
			var gmlFile = tabEl.gmlFile;
			if (gmlFile == null) {
				gmlFile = GmlFile.next;
				if (gmlFile == null) return;
				GmlFile.next = null;
				gmlFile.tabEl = cast tabEl;
				tabEl.gmlFile = gmlFile;
			}
			GmlFile.current = gmlFile;
			aceEditor.setSession(gmlFile.session);
		});
		//
		
		//
		var path = window.localStorage.getItem("autoload");
		if (path != null) {
			project = new Project(path);
		} else project = null;
		//
		trace("hi!");
		return null;
	}
}
