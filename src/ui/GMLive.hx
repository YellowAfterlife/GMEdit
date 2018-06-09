package ui;
import js.RegExp;
import parsers.GmlReader;
import parsers.GmlSeeker;
using tools.HtmlTools;

/**
 * Shows little "live" icons on treeview items in projects that have GMLive
 * @author YellowAfterlife
 */
class GMLive {
	static var rxLive = new RegExp("if\\b\\s*\\("
		+ "\\b(?:live_call|live_call_ext|live_defcall|live_defcall_ext)"
	, "g");
	public static var attr:String = "data-gmlive";
	public static function check(code:String) {
		if (!rxLive.test(code)) return false;
		var q = new GmlReader(code);
		var start = 0;
		function flush(till:Int) {
			var sub = q.substring(start, till);
			return rxLive.test(sub);
		}
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: {
					switch (q.peek()) {
						case "/".code: {
							if (flush(p)) return true;
							q.skipLine();
							start = q.pos;
						};
						case "*".code: {
							if (flush(p)) return true;
							q.skip(); q.skipComment();
							start = q.pos;
						};
					}
				};
			}
		}
		return flush(q.pos);
	}
	public static function update(path:String, has:Bool) {
		var item = TreeView.find(true, { path: path });
		if (item == null) return;
		if (has == item.hasAttribute(attr)) return;
		if (has) {
			item.setAttribute(attr, "");
		} else item.removeAttribute(attr);
		//
		if (GmlSeeker.itemsLeft <= 0) {
			var iter = item;
			var top = TreeView.element;
			while (iter != null && iter != top) {
				if (iter.classList.contains("dir")) {
					if (!has) {
						if (iter.hasAttribute(attr)) {
							if (iter.querySelector('.item[$attr]') == null) {
								iter.removeAttribute(attr);
							}
						}
					} else iter.setAttribute(attr, "");
				}
				iter = iter.parentElement;
			}
		}
	}
	public static function updateAll(?force:Bool) {
		var opt = Preferences.current.showGMLive;
		var all = opt == Everywhere;
		if (!all && !force) return;
		for (dir in TreeView.element.querySelectorEls(".dir")) {
			if (all && dir.querySelector('.item[$attr]') != null) {
				dir.setAttribute(attr, "");
			} else dir.removeAttribute(attr);
		}
	}
	public static function init() {
		#if lwedit
		Reflect.setField(Main.window, "aceTabFlush", function() {
			for (tab in ChromeTabs.impl.tabEls) {
				tab.gmlFile.session.getUndoManager().markClean();
				tab.gmlFile.changed = false;
			}
			//Main.window.
		});
		#end
	}
}
