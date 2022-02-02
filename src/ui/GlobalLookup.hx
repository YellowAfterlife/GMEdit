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
import tools.JsTools;
import tools.NativeString;
import ace.AceMacro;
import gml.GmlAPI;
import tools.macros.SynSugar;
import ui.CommandPalette;
import ui.Preferences;
using tools.HtmlTools;
using tools.NativeString;

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
	
	// this is for checkboxes on the right (as opposed to text-based filters)
	public static var kindFilterCheckboxes:ElementListOf<InputElement>;
	public static var kindFilterCheckboxState:Dictionary<Bool> = new Dictionary();
	static function syncKindFilterCheckboxes() {
		var tf = kindFilterCheckboxState;
		for (cb in kindFilterCheckboxes) {
			var on = cb.checked;
			var kind = cb.dataset.kind;
			tf[kind] = on;
			var kind2 = cb.dataset.kind2;
			if (kind2 != null) tf[kind2] = on;
		}
	}
	
	static var assetHintMapper:Dictionary<String> = new Dictionary();
	
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
				kindFilters = filter.substring(pos + 1).split("|");
				filter = filter.substring(0, pos);
			} else {
				kindFilters = kindFiltersArr;
			}
		}
		syncKindFilterCheckboxes();
		//
		if (filter.length >= 2 || isCmd) {
			var selection = list.selectedOptions.length > 0
				? list.selectedOptions[0].textContent : null;
			var found = 0;
			var foundMap = new Dictionary<Bool>();
			list.selectedIndex = -1;
			var arr = isCmd ? CommandPalette.lookupItems : GmlAPI.gmlLookupItems;
			var matchMode = Preferences.current.globalLookup.matchMode;
			function getHint(name:String) {
				var ac = GmlAPI.gmlAssetComp[name];
				if (ac != null) {
					return ac.meta;
				} else {
					return tools.JsTools.or(GmlAPI.gmlKind[name], GmlAPI.extKind[name]);
				}
			}
			if (filteredList == null || filteredListCmd != isCmd) {
				filteredList = new AceFilteredList(arr, filter);
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
			function addOption(name:String, hint:String):Void {
				//
				var title:String;
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
					if (hint == null) hint = getHint(name);
					if (hint.charCodeAt(0) == "a".code 
						&& hint.charCodeAt(5) == ".".code
						&& hint.startsWith("asset.")
					) {
						var h1 = assetHintMapper[hint];
						if (h1 == null) {
							h1 = hint.fastSubStart(6);
							assetHintMapper[hint] = h1;
						}
						hint = h1;
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
			var filteredItems = filteredList.filtered;
			if (!isCmd) filteredItems = filteredItems.filter(function(item) {
				var hint = item.meta;
				if (hint == null) return false;
				if (kindFilterCheckboxState[hint] == false) return false;
				if (kindFilters == null) return true;
				for (kindFilter in kindFilters) {
					if (NativeString.contains(hint, kindFilter)) return true;
				}
				return false;
			});
			//
			var maxCount = Preferences.current.globalLookup.maxCount;
			if (filteredItems.length > maxCount + 1) {
				var show = filteredItems.slice(0, maxCount);
				var hide = filteredItems.slice(maxCount);
				for (item in show) addOption(item.value, item.meta);
				//
				var more_txt = hide.length + ' more items...';
				var more = addOption_1(found++, more_txt, "", null);
				(cast more).noCache = true;
				more.onclick = function(_) {
					found = maxCount; // causes "more" to be replaced
					for (item in hide) addOption(item.value, item.meta);
				}
			} else {
				for (item in filteredItems) addOption(item.value, item.meta);
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
			if (initialText == null) {
				initialText = aceEditor.getSelectedText();
				if (initialText.indexOf("\n") >= 0) initialText = null;
			}
			filteredList = null;
			filteredListCmd = null;
			field.value = initialText;
			field.select();
			field.focus();
			updateImpl();
		} else hide();
	}
	public static function hide() {
		element.style.display = "none";
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
				var selectedOption = list.selectedOptions[0];
				if (selectedOption != null && selectedOption.onclick != null) {
					selectedOption.click();
				} else {
					var term = list.value;
					if (term == "") term = field.value;
					if (openTerm(term)) hide();
				}
			};
			case KeyboardEvent.DOM_VK_ESCAPE: {
				hide();
			};
		}
	}
	public static var checkboxHTML:String;

	public static function init() {
		filteredList = new AceFilteredList([]);
		element = document.createFormElement();
		element.id = "global-lookup";
		element.classList.add("popout-window");
		element.style.display = "none";
		
		checkboxHTML = {
			var cbHTML = SynSugar.xmls(<html>
				<lbcb checked asset name="sprite">Sprites</lbcb>
				<lbcb checked asset name="tileset">Tilesets</lbcb>
				<lbcb checked asset name="background">Backgrounds</lbcb>
				<lbcb checked asset name="sound">Sounds</lbcb>
				<lbcb checked asset name="path">Paths</lbcb>
				<lbcb checked asset name="script">Scripts</lbcb>
				<lbcb checked asset name="shader">Shaders</lbcb>
				<lbcb checked asset name="font">Fonts</lbcb>
				<lbcb checked asset name="timeline">Timelines</lbcb>
				<lbcb checked asset name="object">Objects</lbcb>
				<lbcb checked asset name="room">Rooms</lbcb>
				<lbcb checked asset name="sequence">Sequences</lbcb>
				<lbcb checked asset name="animcurve">Animation curves</lbcb>
				<lbcb checked asset name="notes">Notes</lbcb>
				<lbcb checked asset name="extension" data-kind2="extfunction">Extensions</lbcb>
				<lbcb name="includedFile">Included files</lbcb>
				<hr/>
				<lbcb name="globalvar">Global variables</lbcb>
				<lbcb name="macro">Macros</lbcb>
				<lbcb name="enums">Enums</lbcb>
				<lbcb name="namespace">Namespaces</lbcb>
			</html>);
			cbHTML = ~/<lbcb(.*?)>(.+?)<\/lbcb>/g.map(cbHTML, function(rx:EReg) {
				var attrs = rx.matched(1);
				var text = rx.matched(2);
				return '<label><input type="checkbox"$attrs/>$text</label>';
			});
			var tmp = document.createDivElement();
			tmp.innerHTML = cbHTML;
			var cbs:ElementListOf<InputElement> = tmp.querySelectorAllAuto('input[type="checkbox"]');
			for (cb in cbs) {
				var isAsset = cb.hasAttribute("asset");
				if (isAsset) cb.removeAttribute("asset");
				if (cb.dataset.kind == null) {
					var name = cb.name;
					var kind = name;
					if (isAsset) kind = "asset." + kind;
					cb.name = "lookup-" + name;
					cb.dataset.kind = kind;
				}
			}
			tmp.innerHTML;
		};
		
		var initHTML = SynSugar.xmls(<html>
			<div class="lookup-main">
				<div class="lookup-query">
					<input name="name" type="text"/>
					<label for="filter">
						<input name="filter" type="checkbox" title="Click to set default filters"/>
					</label>
				</div>
				<select name="comp" size="5"></select>
			</div>
			<div class="lookup-options">
				<fieldset>
					<legend>Look for</legend>
					<checkboxHTML/>
				</fieldset>
			</div>
		</html>);
		initHTML = StringTools.replace(initHTML, "<checkboxHTML/>", checkboxHTML);
		element.innerHTML = initHTML;
		element.onkeydown = onkeydown;
		element.style.width  = Preferences.current.globalLookup.initialWidth + "px";
		element.style.height = Preferences.current.globalLookup.initialHeight + "px";
		
		document.querySelectorAuto("#main", Element).insertAfterSelf(element);
		kindFilterCheckboxes = element.querySelectorAllAuto('.lookup-options input[type="checkbox"]');
		for (cb in kindFilterCheckboxes) {
			var opt = Preferences.current.globalLookup.initialFilters[cb.name];
			if (opt != null) cb.checked = opt;
			cb.addEventListener("change", () -> updateImpl(true));
		}
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
					hide();
				}
			});
		};
		field.onkeyup = function(_) update();
	}
}
