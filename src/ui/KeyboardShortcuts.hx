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
		var isMod = (flags == CTRL || flags == META);
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
			};
			case KeyboardEvent.DOM_VK_F12: {
				if (flags == 0) {
					var pos = aceEditor.getCursorPosition();
					var tk = aceEditor.session.getTokenAtPos(pos);
					openDeclaration(pos, tk);
				}
			};
			case KeyboardEvent.DOM_VK_F: {
				if (isMod) e.preventDefault();
				if (isShiftMod) GlobalSearch.toggle();
			};
			case KeyboardEvent.DOM_VK_T: {
				if (isMod) {
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
	public static function openLink(meta:String, pos:AcePos) {
		// name(def):ctx
		var rx:RegExp = new RegExp("^(.+?)" 
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
		openLocal(name, pos, nav);
		return true;
	}
	public static function openLocal(name:String, pos:AcePos, ?nav:GmlFileNav):Bool {
		//
		if (pos != null) do {
			var scope = gml.GmlScopes.get(pos.row);
			if (scope == null) break;
			var imp = gml.GmlImports.currentMap[scope];
			if (imp == null) break;
			//
			var iter = new AceTokenIterator(aceEditor.session, pos.row, pos.column);
			iter.stepBackward();
			var tk = iter.getCurrentToken();
			if (tk != null && tk.value == ".") {
				iter.stepBackward();
				tk = iter.getCurrentToken();
				if (tk != null && tk.type == "namespace") {
					name = imp.longen[tk.value + "." + name];
					if (name == null) return false;
					var ns = imp.namespaces[tk.value];
				}
			}
			//
			var long = imp.longen[name];
			if (long != null) name = long;
		} while (false);
		//
		var lookup = GmlAPI.gmlLookup[name];
		if (lookup != null) {
			var path = lookup.path;
			var el = TreeView.find(true, { path: path });
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
		var ename = tools.NativeString.escapeProp(name);
		var el = TreeView.element.querySelector('.item[${TreeView.attrIdent}="$ename"]');
		if (el != null) {
			GmlFile.open(el.title, el.getAttribute(TreeView.attrPath), nav);
			return true;
		}
		//
		return false;
	}
	public static function openImportFile(rel:String) {
		var dir = "#import";
		if (!FileWrap.existsSync(dir)) {
			FileWrap.mkdirSync(dir);
		}
		var full = Path.join([dir, rel]);
		var data = null;
		if (!FileWrap.existsSync(full)) {
			full += ".gml";
			if (!FileWrap.existsSync(full)) data = "";
		}
		if (data == null) data = FileWrap.readTextFileSync(full);
		var file = new GmlFile(rel, full, Normal, data);
		GmlFile.openTab(file);
		return true;
	}
	public static function openDeclaration(pos:AcePos, token:AceToken) {
		if (token == null) return false;
		var term = token.value;
		//
		if (token.type.indexOf("importpath") >= 0) {
			if (openImportFile(term.substring(1, term.length - 1))) return true;
		}
		//
		if (term.charCodeAt(0) == "$".code || term.startsWith("0x")) {
			ColorPicker.open(term);
			return true;
		}
		//
		if (term.substring(0, 2) == "@[") {
			var rx = new RegExp("^@\\[(.*)\\]");
			var vals = rx.exec(term);
			if (vals != null) openLink(vals[1], pos);
			return true;
		}
		//
		if (term == "event_inherited" || term == "action_inherited") {
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
		if (openLocal(term, pos, null)) return true;
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
		var session = aceEditor.session;
		var line = session.getLine(pos.row);
		if (line != null && pos.column < line.length
			&& openDeclaration(pos, aceEditor.session.getTokenAtPos(pos))
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
