package ui;
import Main.*;
import electron.Electron;
import electron.FileSystem;
import electron.FileWrap;
import electron.Shell;
import gml.GmlAPI;
import gml.file.GmlFile;
import gml.Project;
import haxe.io.Path;
import js.RegExp;
import js.html.InputElement;
import js.html.KeyboardEvent;
import js.html.Element;
import js.html.MouseEvent;
import js.html.WheelEvent;
import ui.ChromeTabs;
import ace.AceWrap;
import ace.extern.*;
using StringTools;
using tools.HtmlTools;

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
		var isAlt = (flags == ALT);
		var isMod = (flags == CTRL || flags == META);
		var isShift = flags == SHIFT;
		var isShiftMod = (flags == SHIFT + CTRL || flags == SHIFT + META);
		switch (keyCode) {
			case KeyboardEvent.DOM_VK_F2: {
				if (isMod) {
					untyped __js__("formatAceGMLContents();");
				}
			};
			case KeyboardEvent.DOM_VK_F5: {
				// debug
				//document.location.reload(true);
			};
			case KeyboardEvent.DOM_VK_TAB: {
				if (isShiftMod) {
					e.preventDefault();
					prevTab();
				}
				if (isMod) {
					e.preventDefault();
					nextTab();
				}
			};
			case KeyboardEvent.DOM_VK_PAGE_DOWN: {
				if (isMod) {
					e.preventDefault();
					nextTab();
				}
			};
			case KeyboardEvent.DOM_VK_PAGE_UP: {
				if (isMod) {
					e.preventDefault();
					prevTab();
				}
			};
			case KeyboardEvent.DOM_VK_I: {
				if (isShiftMod && Electron != null) {
					Electron.remote.BrowserWindow.getFocusedWindow().toggleDevTools();
				}
			};
			#if !lwedit
			case KeyboardEvent.DOM_VK_R: {
				if (isMod) {
					e.preventDefault();
					if (Project.current != null) {
						Project.current.reload();
					}
				}
			};
			#end
			case KeyboardEvent.DOM_VK_W: {
				if (isMod) {
					e.preventDefault();
					var q = document.querySelector(".chrome-tab-current .chrome-tab-close");
					if (q != null) {
						q.click();
					} else if (document.querySelectorAll(".chrome-tab").length == 0) {
						Project.open("");
					}
				}
				if (isShiftMod) {
					e.preventDefault();
					for (q in document.querySelectorAll(
						".chrome-tab:not(.chrome-tab-current) .chrome-tab-close"
					)) {
						var qe:Element = cast q; qe.click();
					}
				}
			};
			case KeyboardEvent.DOM_VK_S: {
				if (isMod) {
					e.preventDefault();
					var q = GmlFile.current;
					if (q != null) {
						q.save();
					}
				} else if (isShiftMod) {
					e.preventDefault();
					for (tabEl in ChromeTabs.impl.tabEls) {
						var file = tabEl.gmlFile;
						if (file != null) file.save();
					}
				}
				#if lwedit
				ui.liveweb.LiveWeb.saveState();
				#end
			};
			case KeyboardEvent.DOM_VK_F12, KeyboardEvent.DOM_VK_F1: {
				// todo: move to commands
				var pos = aceEditor.getCursorPosition();
				var tk = aceEditor.session.getTokenAtPos(pos);
				if (flags == 0) {
					OpenDeclaration.proc(aceEditor.session, pos, tk);
				} else if (isShift) {
					if (tk != null) GlobalSearch.findReferences(tk.value);
				}
			};
			case KeyboardEvent.DOM_VK_F: {
				if (isMod) e.preventDefault();
				#if !lwedit
				if (isShiftMod) GlobalSearch.toggle();
				#end
			};
			case KeyboardEvent.DOM_VK_T: {
				#if lwedit
				if (isAlt) {
					e.preventDefault();
					GlobalLookup.toggle(">");
				} else
				#end
				if (isShiftMod) {
					e.preventDefault();
					GlobalLookup.toggle(">");
				} else if (isMod) {
					e.preventDefault();
					GlobalLookup.toggle();
				}
			};
			case KeyboardEvent.DOM_VK_9: {
				if (isMod) {
					e.preventDefault();
					var tabs = document.querySelectorEls(".chrome-tab");
					var tabEl:Element = tabs[tabs.length - 1];
					if (tabEl != null) tabEl.click();
				}
			};
			default: {
				if (isMod
				&& keyCode >= KeyboardEvent.DOM_VK_1
				&& keyCode <= KeyboardEvent.DOM_VK_8) {
					e.preventDefault();
					var tabs = document.querySelectorEls(".chrome-tab");
					var tabEl:Element = cast tabs[keyCode - KeyboardEvent.DOM_VK_1];
					if (tabEl != null) tabEl.click();
				}
			};
		}
	}
	//
	public static function mousedown(ev:Dynamic) {
		var dom:MouseEvent = ev.domEvent;
		if (dom.button != 1) return;
		var pos:AcePos = ev.getDocumentPosition();
		var session = aceEditor.session;
		var line = session.getLine(pos.row);
		if (line != null && pos.column < line.length
			&& OpenDeclaration.proc(session, pos, aceEditor.session.getTokenAtPos(pos))
		) {
			if (session.selection.isEmpty()) {
				session.selection.moveTo(pos.row, pos.column);
			}
			dom.preventDefault();
		}
	}
	public static function mousewheel(ev:Dynamic) {
		var dom:WheelEvent = ev.domEvent;
		var flags = getEventFlags(dom);
		if (flags != CTRL && flags != META) return;
		var delta = dom.deltaY;
		if (delta == 0) return;
		delta = delta < 0 ? 1 : -1;
		var obj = aceEditor;
		obj.setOption("fontSize", obj.getOption("fontSize") + delta);
	}
	static function initSystemButtons(closeButton:Element) {
		if (closeButton == null) return;
		inline function getCurrentWindow():Dynamic {
			return Electron.remote.getCurrentWindow();
		}
		closeButton.addEventListener("click", function(_) {
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
	public static function initGlobal() {
		document.body.addEventListener("keydown", KeyboardShortcuts.keydown);
		initSystemButtons(document.querySelector(".system-button.close"));
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
