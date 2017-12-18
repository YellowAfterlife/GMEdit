package;
import Main.*;
import js.html.KeyboardEvent;
import js.html.Element;
import tools.HtmlTools;

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
	public static function handle(e:KeyboardEvent) {
		var flags = (e.ctrlKey ? 1 : 0) | (e.shiftKey ? 2 : 0)
			| (e.altKey ? 4 : 0) | (e.metaKey ? 8 : 0);
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
				var q = GmlFile.current;
				if (q != null) {
					q.save();
				}
			};
			case KeyboardEvent.DOM_VK_F12: {
				if (flags == 0) {
					var tk = aceEditor.session.getTokenAtPos(aceEditor.getCursorPosition());
					if (tk == null) return;
					var el = treeview.querySelector('.item[title="${tk.value}"]');
					if (el != null) {
						Project.openFile(el.title, el.getAttribute("path"));
					}
				}
			};
		}
	}
}
