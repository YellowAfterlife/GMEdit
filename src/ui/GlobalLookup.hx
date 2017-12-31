package ui;
import haxe.ds.Map;
import js.RegExp;
import js.html.Element;
import js.html.InputElement;
import js.html.KeyboardEvent;
import js.html.OptionElement;
import js.html.SelectElement;
import Main.*;
import tools.Dictionary;
import tools.NativeString;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GlobalLookup {
	public static var element:Element;
	public static var field:InputElement;
	public static var list:SelectElement;
	private static var pool:Array<Element> = [];
	private static var updateTimer:Int = null;
	private static var current:String = "";
	private static function updateImpl() {
		updateTimer = null;
		var filter = field.value;
		var i:Int, el:Element;
		if (filter == current) return;
		current = filter;
		if (filter.length >= 2) {
			var pattern = NativeString.escapeRx(filter);
			var regex = new RegExp('^(.*$pattern.*)$', 'gm');
			var selection = list.selectedOptions.length > 0
				? list.selectedOptions[0].textContent : null;
			var data = gml.GmlAPI.gmlLookupText;
			var found = 0;
			var match = regex.exec(data);
			list.selectedIndex = -1;
			while (match != null) {
				var name = match[1];
				var option = list.children[found];
				if (option == null) {
					option = pool.pop();
					if (option == null) option = document.createOptionElement();
					list.appendChild(option);
				}
				option.textContent = name;
				match = regex.exec(data);
				if (name == selection) list.selectedIndex = found;
				found += 1;
			}
			//
			i = list.children.length;
			while (--i >= found) {
				el = list.children[i];
				list.removeChild(el);
				pool.push(el);
			}
			//
			if (list.selectedIndex < 0) list.selectedIndex = 0;
		} else {
			list.selectedIndex = -1;
			i = list.children.length;
			while (--i >= 0) {
				el = list.children[i];
				list.removeChild(el);
				pool.push(el);
			}
		}
	}
	private static inline function update() {
		if (updateTimer == null) updateTimer = window.setTimeout(updateImpl, 100);
	}
	public static function toggle() {
		if (element.style.display == "none") {
			element.style.display = "";
			field.value = aceEditor.getSelectedText();
			field.focus();
			updateImpl();
		} else {
			element.style.display = "none";
		}
	}
	static function onkeydown(e:KeyboardEvent) {
		update();
		var kc = e.keyCode, i:Int;
		switch (kc) {
			case KeyboardEvent.DOM_VK_UP: {
				e.preventDefault();
				i = (list.selectedIndex - 1) % list.children.length;
				if (i < 0) i += list.children.length;
				list.selectedIndex = i;
			};
			case KeyboardEvent.DOM_VK_DOWN: {
				e.preventDefault();
				list.selectedIndex = (list.selectedIndex + 1) % list.children.length;
			};
			case KeyboardEvent.DOM_VK_RETURN: {
				e.preventDefault();
				var term = list.value;
				if (term != "") KeyboardShortcuts.openLocal(term);
				toggle();
			};
			case KeyboardEvent.DOM_VK_ESCAPE: {
				toggle();
			};
		}
	}
	public static function init() {
		element = document.querySelector("#global-lookup");
		field = element.querySelectorAuto("input");
		list = element.querySelectorAuto("select");
		list.onclick = function(_) {
			window.setTimeout(function() {
				var term = list.value;
				if (term != "") {
					KeyboardShortcuts.openLocal(term);
					toggle();
				}
			});
		};
		field.onkeydown = onkeydown;
		field.onkeyup = function(_) update();
	}
}
