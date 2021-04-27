package ui;
import ace.extern.AceAutoCompleteItem;
import ace.extern.AceFilteredList;
import ace.extern.AcePopup;
import electron.Dialog;
import js.lib.RegExp;
import js.html.Element;
import js.html.InputElement;
import js.html.KeyboardEvent;
import js.html.OptionElement;
import js.html.SelectElement;
import Main.*;
import tools.Dictionary;
import tools.NativeString;
import ace.AceMacro;
import gml.GmlAPI;
import tools.macros.SynSugar;
import ui.CommandPalette;
import ui.Preferences;
using tools.HtmlTools;

/**
 * The thing you see when you press Ctrl+T
 * 
 * todo: perhaps use AcePopup for this?
 * @author YellowAfterlife
 */
class GlobalLookup {
	public static var element:Element;
	public static var field:InputElement;
	public static var list:SelectElement;
	private static var pool:Array<Element> = [];
	private static var updateTimer:Int = null;
	private static var current:String = "";
	static var filteredList:AceFilteredList;
	static var filteredListCmd:Bool = null;
	
	public static var useFilters:InputElement;
	private static var kindFiltersArr:Array<String> = null;
	private static var kindFiltersStr:String = "";
	
	private static function updateImpl(?force:Bool) {
		updateTimer = null;
		var filter = field.value;
		var i:Int, el:Element;
		if (!force && filter == current) return;
		current = filter;
		//
		var isCmd = NativeString.startsWith(filter, ">");
		if (isCmd) filter = filter.substring(1);
		var kindFilters:Array<String> = null;
		if (!isCmd) {
			var pos = filter.indexOf(":");
			if (pos >= 0) {
				kindFilters = [filter.substring(pos + 1)];
				filter = filter.substring(0, pos);
			} else {
				kindFilters = kindFiltersArr;
			}
		}
		//
		if (filter.length >= 2 || isCmd) {
			var selection = list.selectedOptions.length > 0
				? list.selectedOptions[0].textContent : null;
			var found = 0;
			var foundMap = new Dictionary<Bool>();
			list.selectedIndex = -1;
			var arr = isCmd ? CommandPalette.lookupList : GmlAPI.gmlLookupList;
			var matchMode = Preferences.current.globalLookup.matchMode;
			if (filteredList == null || filteredListCmd != isCmd) {
				filteredList = new AceFilteredList(arr.map(function(name):AceAutoCompleteItem {
					return cast {value:name};
				}), filter);
				filteredList.gmlMatchMode = matchMode;
				filteredListCmd = isCmd;
			}
			//
			function addOption_1(ind:Int, name:String, title:String, hint:String):Element {
				var option = cast list.children[ind];
				if (option == null || (cast option).noCache) {
					var orig = option;
					option = pool.pop();
					if (option == null) option = document.createOptionElement();
					if (orig != null) {
						list.replaceChild(option, orig);
					} else list.appendChild(option);
				}
				//
				if (hint != null) {
					option.setAttribute("hint", hint);
				} else option.removeAttribute("hint");
				option.title = title != null ? title : "";
				//
				option.textContent = name;
				return option;
			}
			function addOption(name:String):Void {
				//
				var hint:String, title:String;
				if (isCmd) {
					var cmd = CommandPalette.lookupMap[name];
					if (cmd != null) {
						hint = cmd.key;
						title = cmd.title;
					} else {
						hint = null;
						title = null;
					}
				} else {
					var ac = GmlAPI.gmlAssetComp[name];
					if (ac != null) {
						hint = ac.meta;
					} else {
						hint = tools.JsTools.or(GmlAPI.gmlKind[name], GmlAPI.extKind[name]);
					}
					if (kindFilters != null) {
						if (hint == null) return;
						var skip = true;
						for (kindFilter in kindFilters) {
							if (NativeString.contains(hint, kindFilter)) {
								skip = false;
								break;
							}
						}
						if (skip) return;
					}
					title = null;
				}
				//
				var option = addOption_1(found, name, title, hint);
				if (matchMode != AceSmart && name == selection) list.selectedIndex = found;
				found += 1;
			}
			//
			filteredList.shouldSort = true;
			filteredList.setFilter(filter);
			var maxCount = Preferences.current.globalLookup.maxCount;
			if (filteredList.filtered.length > maxCount + 1) {
				var show = filteredList.filtered.slice(0, maxCount);
				var hide = filteredList.filtered.slice(maxCount);
				for (item in show) addOption(item.value);
				//
				var more_txt = hide.length + ' more items...';
				var more = addOption_1(found++, more_txt, "", null);
				(cast more).noCache = true;
				more.onclick = function(_) {
					found = maxCount; // causes "more" to be replaced
					for (item in hide) addOption(item.value);
				}
			} else {
				for (item in filteredList.filtered) addOption(item.value);
			}
			// remove extra items:
			i = list.children.length;
			while (--i >= found) {
				el = list.children[i];
				list.removeChild(el);
				if (!(cast el).noCache) pool.push(el);
			}
			//
			if (list.selectedIndex < 0) list.selectedIndex = 0;
		} else { // remove everything
			list.selectedIndex = -1;
			i = list.children.length;
			while (--i >= 0) {
				el = list.children[i];
				list.removeChild(el);
				if (!(cast el).noCache) pool.push(el);
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
			filteredList = null;
			filteredListCmd = null;
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
			case KeyboardEvent.DOM_VK_TAB: {
				e.preventDefault();
			};
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
				var selectedOption = list.selectedOptions[0];
				if (selectedOption != null && selectedOption.onclick != null) {
					selectedOption.click();
				} else {
					var term = list.value;
					if (term == "") term = field.value;
					if (openTerm(term)) toggle();
				}
			};
			case KeyboardEvent.DOM_VK_ESCAPE: {
				toggle();
			};
		}
	}
	public static function init() {
		filteredList = new AceFilteredList([]);
		element = document.createFormElement();
		element.id = "global-lookup";
		element.classList.add("popout-window");
		element.style.display = "none";
		element.innerHTML = SynSugar.xmls(<html>
			<div>
				<input name="name" type="text" />
				<label for="filter">
					<input name="filter" type="checkbox" title="Click to set default filters"/>
				</label>
			</div>
			<select name="comp" size="5"></select>
		</html>);
		document.querySelectorAuto("#main", Element).insertAfterSelf(element);
		//
		field = element.querySelectorAuto('input[name="name"]');
		field.placeholder = "Resource `name[:type]` or `>command`";
		useFilters = element.querySelectorAuto('input[name="filter"]');
		useFilters.onchange = function() {
			if (useFilters.checked) {
				element.style.display = "none";
				Dialog.showPrompt("New default filters? e.g. `scr|obj`", kindFiltersStr, function(s) {
					kindFiltersStr = s;
					kindFiltersArr = NativeString.splitNonEmpty(s, "|");
					if (kindFiltersArr.length == 0) kindFiltersArr = null;
					element.style.display = "";
					updateImpl(true);
				});
			} else {
				kindFiltersArr = null;
				updateImpl(true);
			}
		}
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
