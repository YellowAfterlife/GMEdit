package ui;
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
		var isCmd = NativeString.startsWith(filter, ">");
		if (filter.length >= 2 || isCmd) {
			if (isCmd) filter = filter.substring(1);
			var pattern = NativeString.escapeRx(filter);
			var selection = list.selectedOptions.length > 0
				? list.selectedOptions[0].textContent : null;
			var found = 0;
			var foundMap = new Dictionary<Bool>();
			list.selectedIndex = -1;
			var data = isCmd ? CommandPalette.lookupText : gml.GmlAPI.gmlLookupText;
			//
			function addOption(name:String):Void {
				var option = list.children[found];
				if (option == null) {
					option = pool.pop();
					if (option == null) option = document.createOptionElement();
					list.appendChild(option);
				}
				//
				var hint:String, title:String;
				if (isCmd) {
					var cmd = CommandPalette.lookupMap[name];
					hint = cmd.key;
					title = cmd.title;
				} else {
					hint = null;
					title = null;
				}
				if (hint != null) {
					option.setAttribute("hint", hint);
				} else option.removeAttribute("hint");
				option.title = title != null ? title : "";
				//
				option.textContent = name;
				if (name == selection) list.selectedIndex = found;
				found += 1;
			}
			//
			if (pattern != "") {
				var directMatch = new RegExp('^$pattern$', 'gmi').exec(data);
				if (directMatch != null) {
					foundMap.set(directMatch[0], true);
					addOption(directMatch[0]);
				}
				//
				for (iter in 0 ... 2) {
					var ipatt = iter == 0 ? '^($pattern.*)$' : '^(.+$pattern.*)$';
					var regex = new RegExp(ipatt, 'gmi');
					var match = regex.exec(data);
					while (match != null) {
						var name = match[1];
						if (!foundMap[name]) {
							foundMap.set(name, true);
							addOption(name);
						}
						match = regex.exec(data);
					}
				}
			} else {
				for (v in CommandPalette.lookupList) addOption(v);
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
	public static function toggle(?initialText:String) {
		if (element.style.display == "none") {
			element.style.display = "";
			if (initialText == null) initialText = aceEditor.getSelectedText();
			field.value = initialText;
			field.focus();
			updateImpl();
		} else {
			element.style.display = "none";
		}
	}
	static function openTerm(term:String):Bool {
		if (NativeString.startsWith(field.value, ">")) {
			var cmd = CommandPalette.lookupMap[term];
			if (cmd == null) return false;
			cmd.exec();
			return true;
		} else {
			return OpenDeclaration.openLocal(term, null);
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
				if (term == "") term = field.value;
				if (openTerm(term)) toggle();
			};
			case KeyboardEvent.DOM_VK_ESCAPE: {
				toggle();
			};
		}
	}
	public static function init() {
		element = document.querySelector("#global-lookup");
		field = element.querySelectorAuto("input");
		field.placeholder = "Resource name or >command";
		list = element.querySelectorAuto("select");
		list.onclick = function(_) {
			window.setTimeout(function() {
				var term = list.value;
				if (term != "") {
					openTerm(term);
					toggle();
				}
			});
		};
		field.onkeydown = onkeydown;
		field.onkeyup = function(_) update();
	}
}
