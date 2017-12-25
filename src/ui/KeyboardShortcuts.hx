package ui;
import Main.*;
import electron.Shell;
import gml.GmlAPI;
import gml.GmlFile;
import gml.Project;
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
		//
		switch (e.keyCode) {
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
					if (q != null) q.click();
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
					var tk = aceEditor.session.getTokenAtPos(aceEditor.getCursorPosition());
					openDeclaration(tk);
				}
			};
		}
	}
	public static function openDeclaration(tk:AceToken) {
		if (tk == null) return;
		var term = tk.value;
		var el = TreeView.element.querySelector('.item[${TreeView.attrIdent}="$term"]');
		if (el != null) {
			GmlFile.open(el.title, el.getAttribute(TreeView.attrPath));
			return;
		}
		//
		var lookup = GmlAPI.gmlLookup[term];
		el = TreeView.element.querySelector('.item[${TreeView.attrIdent}="$lookup"]');
		if (el != null) {
			var file = GmlFile.open(el.title, el.getAttribute(TreeView.attrPath));
			if (file != null) {
				var def = new js.RegExp("^#define[ \t]" + term, "");
				var session = file.session;
				for (row in 0 ... session.getLength()) {
					var line = session.getLine(row);
					if (def.test(line)) {
						window.setTimeout(function() {
							aceEditor.gotoLine(row + 1, line.length);
						});
						break;
					}
				}
			}
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
		openDeclaration(aceEditor.session.getTokenAtPos(pos));
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
}

typedef HasKeyboardFlags = {
	public var ctrlKey (default, null):Bool;
	public var shiftKey(default, null):Bool;
	public var altKey  (default, null):Bool;
	public var metaKey (default, null):Bool;
};
