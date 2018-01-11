package ui;
import Main.*;
import electron.Electron;
import electron.Shell;
import gml.GmlAPI;
import gml.GmlFile;
import gml.Project;
import js.RegExp;
import js.html.InputElement;
import js.html.KeyboardEvent;
import js.html.Element;
import js.html.MouseEvent;
import js.html.WheelEvent;
import ui.ChromeTabs;
import ace.AceWrap;
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
				if (flags == CTRL || flags == META) {
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
				if (flags == CTRL || flags == META) {
					var q = GmlFile.current;
					if (q != null) {
						q.save();
					}
				} else if (flags == CTRL + SHIFT || flags == META + SHIFT) {
					for (tabEl in ChromeTabs.impl.tabEls) {
						var file = tabEl.gmlFile;
						if (file != null) file.save();
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
				if (flags == CTRL + SHIFT || flags == META + SHIFT) GlobalSearch.toggle();
			};
			case KeyboardEvent.DOM_VK_T: {
				if (flags == CTRL || flags == META) GlobalLookup.toggle();
			};
			case KeyboardEvent.DOM_VK_9: {
				if (flags == CTRL || flags == META) {
					var tabs = document.querySelectorEls(".chrome-tab");
					var tabEl:Element = tabs[tabs.length - 1];
					if (tabEl != null) tabEl.click();
				}
			};
			default: {
				if ((flags == CTRL || flags == META)
				&& keyCode >= KeyboardEvent.DOM_VK_0
				&& keyCode <= KeyboardEvent.DOM_VK_8) {
					var tabs = document.querySelectorEls(".chrome-tab");
					var tabEl:Element = cast tabs[keyCode - KeyboardEvent.DOM_VK_1];
					if (tabEl != null) tabEl.click();
				}
			};
		}
	}
	//
	public static function openLink(meta:String) {
		// name(def):ctx
		var rx:RegExp = new RegExp("^(\\w+)" 
			+ "(?:\\(([^)]*)\\))?"
			+ "(?::(.+))?$");
		var vals = rx.exec(meta);
		if (vals == null) return false;
		var name = vals[1];
		var def = vals[2];
		var ctx = vals[3];
		var nav:GmlFileNav = { def: def };
		if (ctx != null) {
			var rs = "(\\d+)(?:(\\d+))?";
			rx = new RegExp("^" + rs + "$");
			vals = rx.exec(ctx);
			var ctxRow = null, ctxCol = null;
			if (vals == null) {
				rx = new RegExp("^([^:]+):" + rs + "$");
				vals = rx.exec(ctx);
				if (vals != null) {
					nav.ctx = vals[1];
					ctxRow = vals[2];
					ctxCol = vals[3];
				} else nav.ctx = ctx;
			} else {
				ctxRow = vals[1];
				ctxCol = vals[2];
			}
			if (ctxRow != null) nav.pos = {
				row: Std.parseInt(ctxRow) - 1,
				column: ctxCol != null ? Std.parseInt(ctxCol) - 1 : 0
			};
		}
		openLocal(name, nav);
		return true;
	}
	public static function openLocal(name:String, ?nav:GmlFileNav):Bool {
		//
		var lookup = GmlAPI.gmlLookup[name];
		if (lookup != null) {
			var path = lookup.path;
			var el = TreeView.element.querySelector('.item['
				+ TreeView.attrPath + '="' + path + '"]');
			if (el != null) {
				if (nav != null) {
					if (nav.def == null) nav.def = lookup.sub;
					if (nav.pos != null) {
						nav.pos.row += lookup.row;
						nav.pos.column += lookup.col;
					} else nav.pos = { row: lookup.row, column: lookup.col };
				}; else nav = {
					def: lookup.sub,
					pos: { row: lookup.row, column: lookup.col }
				};
				GmlFile.open(el.title, path, nav);
				return true;
			}
		}
		//
		var el = TreeView.element.querySelector('.item[${TreeView.attrIdent}="$name"]');
		if (el != null) {
			GmlFile.open(el.title, el.getAttribute(TreeView.attrPath), nav);
			return true;
		}
		//
		return false;
	}
	public static function openDeclaration(pos:AcePos, token:AceToken) {
		if (token == null) return false;
		var term = token.value;
		//
		if (term.charCodeAt(0) == "$".code || term.startsWith("0x")) {
			ColorPicker.open(term);
			return true;
		}
		//
		if (term.substring(0, 2) == "@[") {
			var rx = new RegExp("^@\\[(.*)\\]");
			var vals = rx.exec(term);
			if (vals != null) openLink(vals[1]);
			return true;
		}
		//
		if (openLocal(term, null)) return true;
		//
		if (term == "event_inherited") {
			var def = gml.GmlScopes.get(pos.row);
			if (def == "") return false;
			var file = GmlFile.current;
			var path = file.path;
			switch (file.kind) {
				case GmxObjectEvents: return gmx.GmxObject.openEventInherited(path, def) != null;
				case YyObjectEvents: return yy.YyObject.openEventInherited(path, def) != null;
				default: return false;
			}
			return true;
		}
		//
		var helpURL = GmlAPI.helpURL;
		if (helpURL != null) {
			var helpLookup = GmlAPI.helpLookup;
			if (helpLookup != null) {
				var helpTerm = helpLookup[term];
				if (helpTerm != null) {
					Shell.openExternal(helpURL.replace("$1", helpTerm));
					return true;
				}
			} else {
				Shell.openExternal(helpURL.replace("$1", term));
				return true;
			}
		}
		return false;
	}
	public static function mousedown(ev:Dynamic) {
		var dom:MouseEvent = ev.domEvent;
		if (dom.button != 1) return;
		var pos:AcePos = ev.getDocumentPosition();
		var line = aceEditor.session.getLine(pos.row);
		if (line != null && pos.column < line.length
			&& openDeclaration(pos, aceEditor.session.getTokenAtPos(pos))
		) {
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
