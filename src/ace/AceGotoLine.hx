package ace;
import gml.GmlAPI;
import gml.GmlFile;
import js.RegExp;
import js.html.DivElement;
import js.html.Element;
import js.html.Event;
import js.html.InputElement;
import tools.NativeString;
import Main.*;
import ui.KeyboardShortcuts;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class AceGotoLine {
	public static var inst:AceGotoLine;
	//
	public var editor:AceWrap;
	public var element:Element;
	public var input:InputElement;
	public var closeButton:Element;
	public var keyHandler:Dynamic;
	public function new(editor:AceWrap) {
		this.editor = editor;
		//
		var div = document.createDivElement();
		div.innerHTML = '<div class="ace_search right">'
			+ '<span action="hide" class="ace_searchbtn_close"></span>'
			+ '<div class="ace_search_form">'
			+ '<input class="ace_search_field" placeholder="Go to line, place, or place:line" spellcheck="false"></input>'
			+ '</div>'
		+ '</div>';
		element = div.firstElementChild;
		input = element.querySelectorAuto('.ace_search_field');
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
		var HashHandler = AceWrap.require("ace/keyboard/hash_handler").HashHandler;
		keyHandler = AceMacro.jsNew(HashHandler);
		keyHandler.bindKeys({
			"Esc": function(q:AceGotoLine) {
				window.setTimeout(function() q.hide());
			},
			"Return": function(q:AceGotoLine) {
				var val = q.input.value;
				var row = Std.parseInt(q.input.value);
				var valColon = val.indexOf(":");
				if (row == null || valColon >= 0) {
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
				} else {
					row -= 1;
					if (GmlExternAPI.gmlResetOnDefine) {
						var ctr = AceStatusBar.contextRow;
						if (ctr >= 0) row += ctr + 1;
					}
					editor.gotoLine0(row, 0);
				}
				window.setTimeout(function() q.hide());
			}
		});
	}
	public function hide() {
		element.style.display = "none";
		editor.keyBinding.removeKeyboardHandler(keyHandler);
		editor.focus();
	}
	public function show() {
		element.style.display = "";
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
