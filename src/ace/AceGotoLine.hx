package ace;
import ace.AceSessionData;
import ace.extern.AceAutoCompleteItem;
import ace.extern.AceAutoCompleteItems;
import ace.extern.AceFilteredList;
import ace.extern.AceSession;
import gml.GmlAPI;
import gml.file.GmlFile;
import js.html.KeyboardEvent;
import js.html.SelectElement;
import js.lib.RegExp;
import js.html.DivElement;
import js.html.Element;
import js.html.Event;
import js.html.InputElement;
import tools.NativeString;
import Main.*;
import tools.macros.SynSugar;
import ui.KeyboardShortcuts;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class AceGotoLine {
	public static var inst:AceGotoLine;
	private static var HashHandler:Dynamic;
	//
	public var editor:AceWrap;
	public var element:Element;
	public var input:InputElement;
	public var closeButton:Element;
	public var keyHandler:Dynamic;
	public var select:SelectElement;
	
	public var autoCompletionItems:AceAutoCompleteItems = null;
	public var selectedItem:AceAutoCompleteItem;
	public var filteredList:AceFilteredList;
	public var filteredItems:AceAutoCompleteItems;
	//
	public function new(editor:AceWrap) {
		this.editor = editor;
		//
		var div = document.createDivElement();
		div.innerHTML = SynSugar.xmls(<html>
			<div class="ace_search ace_goto right">
			<span action="hide" class="ace_searchbtn_close"></span>
			<div class="ace_search_form">
				<input class="ace_search_field" placeholder="Go to line, place, or place:line" spellcheck="false"></input>
			</div>
			<select class="ace_goto_comp" size="5"></select>
		</html>);
		element = div.firstElementChild;
		input = element.querySelectorAuto('.ace_search_field');
		select = element.querySelectorAuto('.ace_goto_comp');
		function restoreAndHide() {
			if (element.style.display != "") return;
			var session = editor.session;
			if (session.gmlGotoOrigState != null) {
				AceSessionData.set(session.gmlEditor, session.gmlGotoOrigState);
				session.gmlGotoOrigState = null;
			}
			window.setTimeout(() -> hide());
		}
		input.addEventListener("keydown", function(e:KeyboardEvent) {
			if (e.keyCode == KeyboardEvent.DOM_VK_ESCAPE) {
				restoreAndHide();
				return;
			}
			if (e.keyCode == KeyboardEvent.DOM_VK_UP || e.keyCode == KeyboardEvent.DOM_VK_DOWN) {
				if (filteredItems == null) return;
				var delta = 0;
				if (e.keyCode == KeyboardEvent.DOM_VK_UP) delta--;
				if (e.keyCode == KeyboardEvent.DOM_VK_DOWN) delta++;
				
				var index = filteredItems.indexOf(selectedItem);
				if (index >= 0) {
					index = (index + delta) % filteredItems.length;
					if (index < 0) index += filteredItems.length;
				} else index = 0;
				select.selectedIndex = index;
				selectedItem = filteredItems[index];
				e.preventDefault();
				return;
			}
		});
		input.addEventListener("keyup", function(e:KeyboardEvent) {
			var ret = (e.keyCode == KeyboardEvent.DOM_VK_RETURN);
			var session = editor.session;
			if (!ret && session.gmlGotoOrigState == null) {
				session.gmlGotoOrigState = AceSessionData.get(session.gmlEditor);
			}
			//
			var val = NativeString.trimBoth(input.value);
			if (val != "") apply(val);
			if (ret) hide();
		});
		input.addEventListener("blur", function(e:KeyboardEvent) {
			window.setTimeout(function() {
				if (document.activeElement == input) return;
				restoreAndHide();
			});
		});
		select.addEventListener("mousedown", function(_) {
			window.setTimeout(function() {
				if (filteredItems == null) return;
				selectedItem = filteredItems[select.selectedIndex];
				if (selectedItem != null) {
					editor.gotoLine0(Std.parseInt(selectedItem.value), 0);
					hide();
				}
			});
		});
		closeButton = element.querySelector('.ace_searchbtn_close');
		editor.renderer.scroller.appendChild(element);
		//
		var event = AceWrap.require("ace/lib/event");
		event.addListener(element, "mousedown", function(e:Event) {
			window.setTimeout(function() input.focus());
			e.stopPropagation();
		});
		event.addListener(element, "click", function(e) {
			if (e.target == closeButton) hide();
			e.stopPropagation();
		});
		var keyUtil = AceWrap.require("ace/lib/keys");
		event.addCommandKeyListener(element, function(e, hashId, keyCode) {
            var keyString = keyUtil.keyCodeToString(keyCode);
            var command = keyHandler.findKeyCommand(hashId, keyString);
            if (command != null && command.exec != null) {
                command.exec(this);
                event.stopEvent(e);
            }
        });
		//
		HashHandler = AceWrap.require("ace/keyboard/hash_handler").HashHandler;
		keyHandler = js.Syntax.construct(HashHandler);
		keyHandler.bindKeys({
			"Esc": function(q:AceGotoLine) {
				//
			},
			"Return": function(q:AceGotoLine) {
				//
			}
		});
	}
	public function apply(val:String) {
		if (val == "") {
			selectedItem = null;
			filteredItems = null;
			select.clearInner();
			return;
		}
		var row = Std.parseInt(val);
		var valColon = val.indexOf(":");
		if (row == null || valColon >= 0) {
			if (autoCompletionItems != null) {
				filteredItems = filteredList.filterCompletions(autoCompletionItems, val);
				if (filteredItems.indexOf(selectedItem) < 0) {
					selectedItem = filteredItems[0];
				}
				select.clearInner();
				for (item in filteredItems) {
					var option = document.createOptionElement();
					option.dataset.meta = item.meta;
					option.setInnerText(item.caption);
					if (selectedItem == item) option.selected = true;
					select.appendChild(option);
				}
				if (selectedItem != null) {
					editor.gotoLine0(Std.parseInt(selectedItem.value), 0);
				}
			} else {
				select.clearInner();
				var nav:GmlFileNav;
				if (valColon >= 0) {
					nav = { };
					var def = val.substring(0, valColon);
					if (def != "") nav.def = def;
					var ctx = val.substring(valColon + 1);
					row = Std.parseInt(ctx);
					if (row != null) {
						nav.pos = { row: row - 1, column: 0 };
					} else {
						valColon = ctx.indexOf(":");
						if (valColon >= 0) {
							nav.ctx = ctx.substring(0, valColon);
							row = Std.parseInt(ctx.substring(valColon + 1));
							if (row != null) nav.pos = { row: row - 1, column: 0 };
						} else nav.ctx = ctx;
					}
				} else nav = { def: val };
				if (!GmlFile.current.navigate(nav)) return;
			}
		} else { // numeric
			selectedItem = null;
			filteredItems = null;
			select.clearInner();
			row -= 1;
			if (GmlExternAPI.gmlResetOnDefine) {
				var rxReset = new RegExp('^(?:#define|#event|#section|#moment|#target)\\b');
				var ctr = editor.selection.lead.row;
				while (ctr >= 0) {
					if (rxReset.test(editor.session.getLine(ctr))) break;
					ctr--;
				}
				if (ctr >= 0) row += ctr + 1;
			}
			editor.gotoLine0(row, 0);
		}
	}
	public function hide() {
		element.style.display = "none";
		editor.keyBinding.removeKeyboardHandler(keyHandler);
		editor.focus();
	}
	public function show() {
		var editCode = editor.session.gmlEditor;
		autoCompletionItems = editCode.kind.gatherGotoTargets(editCode);
		var hasAC = autoCompletionItems != null;
		filteredList = hasAC ? new AceFilteredList(autoCompletionItems) : null;
		if (hasAC) filteredList.gmlMatchMode = AceSmart;
		select.setDisplayFlag(hasAC);
		select.clearInner();
		selectedItem = null;
		element.setDisplayFlag(true);
		input.value = "";// + (editor.session.selection.lead.row + 1);
		input.focus();
		input.select();
		editor.keyBinding.addKeyboardHandler(keyHandler);
	}
	public static function run(editor:AceWrap) {
		if (inst == null) inst = new AceGotoLine(editor);
		inst.show();
	}
}
