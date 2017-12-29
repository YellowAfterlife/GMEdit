package ui;
import Main.*;
import electron.Electron;
import electron.Shell;
import gml.GmlAPI;
import gml.GmlFile;
import gml.Project;
import js.html.InputElement;
import js.html.KeyboardEvent;
import js.html.Element;
import js.html.MouseEvent;
import js.html.WheelEvent;
import tools.HtmlTools;
import ace.AceWrap;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class KeyboardShortcuts {
	static function prevTab() {
		var tab = document.querySelector(".chrome-tab-current");
		if (tab == null) return;
		var next = tab.previousElementSibling;
		if (next == null) next = tab.parentElement.lastElementChild;
		if (next != null) next.click();
	}
	static function nextTab() {
		var tab = document.querySelector(".chrome-tab-current");
		if (tab == null) return;
		var next = tab.nextElementSibling;
		if (next == null) next = tab.parentElement.firstElementChild;
		if (next != null) next.click();
	}
	private static inline var NONE = 0;
	private static inline var CTRL = 1;
	private static inline var SHIFT = 2;
	private static inline var ALT = 4;
	private static inline var META = 8;
	private static inline function getEventFlags(e:HasKeyboardFlags):Int {
		var flags = 0x0;
		if (e.ctrlKey) flags |= CTRL;
		if (e.shiftKey) flags |= SHIFT;
		if (e.altKey) flags |= ALT;
		if (e.metaKey) flags |= META;
		return flags;
	}
	public static function keydown(e:KeyboardEvent) {
		var flags = getEventFlags(e);
		var keyCode = e.keyCode;
		switch (keyCode) {
			case KeyboardEvent.DOM_VK_F5: {
				// debug
				//document.location.reload(true);
			};
			case KeyboardEvent.DOM_VK_TAB: {
				if (flags == 3) prevTab();
				if (flags == 1) nextTab();
			};
			case KeyboardEvent.DOM_VK_PAGE_DOWN: {
				if (flags == 1) nextTab();
			};
			case KeyboardEvent.DOM_VK_PAGE_UP: {
				if (flags == 1) prevTab();
			};
			case KeyboardEvent.DOM_VK_I: {
				if (flags == 3) {
					untyped require('remote').getCurrentWindow().toggleDevTools();
				}
			};
			case KeyboardEvent.DOM_VK_R: {
				if (flags == CTRL) {
					if (Project.current != null) {
						Project.current.reload();
					}
				}
			};
			case KeyboardEvent.DOM_VK_W: {
				if (flags == 1) {
					var q = document.querySelector(".chrome-tab-current .chrome-tab-close");
					if (q != null) {
						q.click();
					} else if (document.querySelectorAll(".chrome-tab").length == 0) {
						Project.open("");
					}
				}
				if (flags == 3) {
					for (q in document.querySelectorAll(
						".chrome-tab:not(.chrome-tab-current) .chrome-tab-close"
					)) {
						var qe:Element = cast q; qe.click();
					}
				}
			};
			case KeyboardEvent.DOM_VK_S: {
				if (flags == CTRL) {
					var q = gml.GmlFile.current;
					if (q != null) {
						q.save();
					}
				}
			};
			case KeyboardEvent.DOM_VK_F12: {
				if (flags == 0) {
					var pos = aceEditor.getCursorPosition();
					var tk = aceEditor.session.getTokenAtPos(pos);
					openDeclaration(pos, tk);
				}
			};
			case KeyboardEvent.DOM_VK_F: {
				/*if (flags == CTRL + SHIFT) {
					var name = "Search results";
					GmlFile.next = new GmlFile(name, null, SearchResults, "hello");
					ChromeTabs.addTab(name);
					window.setTimeout(function() {
						aceEditor.focus();
					});
				}*/
			};
			default: {
				if (flags == CTRL
				&& keyCode >= KeyboardEvent.DOM_VK_0
				&& keyCode <= KeyboardEvent.DOM_VK_9) {
					var tabId = keyCode - KeyboardEvent.DOM_VK_1;
					if (tabId < 0) tabId = 9;
					var tabs = document.querySelectorAll(".chrome-tab");
					var tabEl:Element = cast tabs[tabId];
					if (tabEl != null) tabEl.click();
				}
			};
		}
	}
	//
	public static function openDeclaration(pos:AcePos, token:AceToken) {
		var term = token.value;
		//
		if (term.charCodeAt(0) == "$".code || term.startsWith("0x")) {
			ColorPicker.open(term);
			return;
		}
		//
		var lookup = GmlAPI.gmlLookup[term];
		if (lookup != null) {
			var path = lookup.path;
			var el = TreeView.element.querySelector('.item['
				+ TreeView.attrPath + '="' + path + '"]');
			if (el != null) {
				var pos = { row: lookup.row, column: lookup.col };
				var sub = lookup.sub;
				var nav:GmlFileNav = sub != null ? Script(sub, pos) : Offset(pos);
				GmlFile.open(el.title, path, nav);
				return;
			}
		}
		//
		var el = TreeView.element.querySelector('.item[${TreeView.attrIdent}="$term"]');
		if (el != null) {
			GmlFile.open(el.title, el.getAttribute(TreeView.attrPath));
			return;
		}
		//
		var helpURL = GmlAPI.helpURL;
		if (helpURL != null) {
			var helpLookup = GmlAPI.helpLookup;
			if (helpLookup != null) {
				var helpTerm = helpLookup[term];
				if (helpTerm != null) {
					Shell.openExternal(helpURL.replace("$1", helpTerm));
				}
			} else Shell.openExternal(helpURL.replace("$1", term));
		}
	}
	public static function mousedown(ev:Dynamic) {
		var dom:MouseEvent = ev.domEvent;
		if (dom.button != 1) return;
		dom.preventDefault();
		var pos:AcePos = ev.getDocumentPosition();
		openDeclaration(pos, aceEditor.session.getTokenAtPos(pos));
	}
	public static function mousewheel(ev:Dynamic) {
		var dom:WheelEvent = ev.domEvent;
		var flags = getEventFlags(dom);
		if (flags != CTRL) return;
		var delta = dom.deltaY;
		if (delta == 0) return;
		delta = delta < 0 ? 1 : -1;
		var obj = aceEditor;
		obj.setOption("fontSize", obj.getOption("fontSize") + delta);
	}
	public static function initGlobal() {
		inline function getCurrentWindow():Dynamic {
			return Electron.remote.getCurrentWindow();
		}
		document.body.addEventListener("keydown", KeyboardShortcuts.keydown);
		document.querySelector(".system-button.close").addEventListener("click", function(_) {
			var wnd = getCurrentWindow();
			if (wnd != null) wnd.close();
		});
		document.querySelector(".system-button.maximize").addEventListener("click", function(_) {
			var wnd = getCurrentWindow();
			if (wnd != null) {
				if (wnd.isMaximized()) {
					wnd.unmaximize();
				} else wnd.maximize();
			}
		});
		document.querySelector(".system-button.minimize").addEventListener("click", function(_) {
			var wnd = getCurrentWindow();
			if (wnd != null) wnd.minimize();
		});
	}
	public static function initEditor() {
		aceEditor.on("mousedown", KeyboardShortcuts.mousedown);
		aceEditor.on("mousewheel", KeyboardShortcuts.mousewheel);
		untyped aceEditor.debugShowToken = function() {
			aceEditor.on("mousemove", function(ev:Dynamic) {
				var pos:AcePos = ev.getDocumentPosition();
				var tk = aceEditor.session.getTokenAtPos(pos);
				if (tk != null) ace.AceStatusBar.setStatusHint(tk.type);
			});
		};
	}
}

typedef HasKeyboardFlags = {
	public var ctrlKey (default, null):Bool;
	public var shiftKey(default, null):Bool;
	public var altKey  (default, null):Bool;
	public var metaKey (default, null):Bool;
};
