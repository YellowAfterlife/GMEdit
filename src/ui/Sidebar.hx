package ui;
import js.html.DivElement;
import js.html.Element;
import js.html.OptionElement;
import js.html.SelectElement;
import tools.Dictionary;
using tools.HtmlTools;

/**
 * The secondary sidebar for plugins
 * @author YellowAfterlife
 */
@:keep class Sidebar {
	static var list:Array<SidebarItem> = [];
	static var map:Dictionary<SidebarItem> = new Dictionary();
	static var select:SelectElement;
	static var panel:DivElement;
	static var sizer:DivElement;
	static var outer:DivElement;
	private static function sync() {
		var n = list.length;
		var v = n == 0 ? "none" : "";
		if (sizer.style.display != v) {
			sizer.style.display = v;
			outer.style.display = v;
			Splitter.syncMain();
		}
		select.style.display = n <= 1 ? "none" : "";
	}
	public static function set(name:String) {
		var item = map[name];
		if (item == null) return;
		var curr = panel.children[0];
		if (curr == item.el) return;
		var fn = select.onchange;
		select.onchange = null;
		select.value = name;
		if (curr != null) panel.removeChild(curr);
		panel.appendChild(item.el);
		select.onchange = fn;
		/*
		if (panel.children[0] != null) {
			panel.removeChild(panel.children[0]);
		}
		panel.appendChild(item.el);*/
	}
	public static function add(name:String, el:Element) {
		var item = map[name];
		if (item != null) list.remove(item);
		item = new SidebarItem(name, el);
		map.set(name, item);
		list.push(item);
		select.appendChild(item.opt);
		if (panel.children[0] == null) {
			set(name);
		}
		sync();
	}
	public static function remove(name:String, ?el:Element):Bool {
		var item = map[name];
		if (item == null) return false;
		if (el != null && item.el != el) return false;
		map.remove(name);
		list.remove(item);
		select.removeChild(item.opt);
		if (panel.children[0] == item.el) {
			panel.removeChild(item.el);
			if (list.length > 0) set(list[0].name);
		}
		sync();
		return true;
	}
	public static function init() {
		select = Main.document.querySelectorAuto("#misc-select");
		panel = Main.document.querySelectorAuto("#misc-panel");
		sizer = Main.document.querySelectorAuto("#misc-splitter-td");
		outer = Main.document.querySelectorAuto("#misc-td");
		select.onchange = function(_) {
			set(select.value);
		};
	}
}
private class SidebarItem {
	public var el:Element;
	public var opt:OptionElement;
	public var name:String;
	public function new(name:String, el:Element) {
		this.name = name;
		this.el = el;
		opt = Main.document.createOptionElement();
		HtmlTools.setInnerText(opt, name);
	}
}

