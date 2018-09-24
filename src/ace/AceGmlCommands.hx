package ace;
import ace.AceWrap;
import ace.extern.*;
import ace.extern.AceCommandManager;
import js.RegExp;

/**
 * GMS-style keybinds, as per
 * https://docs2.yoyogames.com/source/_build/1_overview/2_quick_start/8_shortcuts.html
 * @author YellowAfterlife
 */
class AceGmlCommands {
	public static function init() {
		var commands = Main.aceEditor.commands;
		inline function wm(win:String, mac:String):AceCommandKey {
			return { win: win, mac: mac };
		}
		commands.addCommand({
			name: "startAutocomplete",
			exec: function(editor:AceWrap) {
				if (editor.completer != null) {
					editor.completer.showPopup(editor);
				}
			},
			bindKey: "Ctrl-Space|Ctrl-Shift-Space|Alt-Space"
		});
		commands.addCommand({
			name: "showKeyboardShortcuts",
			bindKey: wm("Ctrl-Alt-h", "Command-Alt-h"),
			exec: function(editor) {
				AceWrap.loadModule("ace/ext/keybinding_menu", function(module) {
					module.init(editor);
					untyped editor.showKeyboardShortcuts();
				});
			}
		});
		#if lwedit
		commands.addCommand({
			name: "lw_execute",
			bindKey: {win: "Ctrl-Enter", mac: "Command-Enter|Ctrl-Enter"},
			exec: function(editor) {
				Main.document.getElementById("refresh").click();
			}
		});
		#else
		commands.bindKey(wm("Ctrl-Enter", "Command-Enter"), "toggleFoldWidget");
		#end
		commands.bindKey(wm("Ctrl-M", "Command-M"), "foldall");
		commands.bindKey(wm("Ctrl-U", "Command-U"), "unfoldall");
		commands.bindKey(wm("Ctrl-Alt-Up", "Command-Alt-Up"), "movelinesup");
		commands.bindKey(wm("Ctrl-Alt-Down", "Command-Alt-Down"), "movelinesdown");
		commands.bindKey(wm("Alt-Shift-Up", "Alt-Shift-Up"), "addCursorAbove");
		commands.bindKey(wm("Alt-Shift-Down", "Alt-Shift-Down"), "addCursorBelow");
		commands.bindKey(wm("Ctrl-K", "Command-K"), "togglecomment");
		//
		var findRxs = "^#define\\b|^#event\\b|^#moment\\b|^#section\\b";
		var findRx0 = new RegExp('(?:$findRxs|#region\\b|//{|//#region)');
		//var findRx1 = new RegExp('(?:$findRxs)');
		function findFoldImpl(editor:AceWrap, fwd:Bool, select:Bool):Void {
			var session = editor.session;
			var foldWidgets = session.foldWidgets;
			var row = editor.selection.lead.row;
			var steps = fwd ? (session.getLength() - 1 - row) : row;
			var delta = fwd ? 1 : -1;
			var rx = findRx0;
			while (--steps >= 0) {
				row += delta;
				if (foldWidgets[row] == null) {
					foldWidgets[row] = session.getFoldWidget(row);
				}
				if (foldWidgets[row] != "start") continue;
				if (session.getFoldAt(row, 0) != null) continue;
				if (!rx.test(session.getLine(row))) continue;
				var col = session.getLine(row).length;
				if (select) {
					editor.selection.selectTo(row, 0);
				} else editor.gotoLine0(row, col);
				break;
			}
		}
		commands.addCommand({
			name: "gotoNextFoldRegion",
			bindKey: wm("Ctrl-Down", "Command-Down"),
			exec: function(editor:AceWrap) findFoldImpl(editor, true, false),
		});
		commands.addCommand({
			name: "gotoPreviousFoldRegion",
			bindKey: wm("Ctrl-Up", "Command-Up"),
			exec: function(editor:AceWrap) findFoldImpl(editor, false, false),
		});
		commands.addCommand({
			name: "selectNextFoldRegion",
			bindKey: wm("Ctrl-Shift-Down", "Command-Shift-Down"),
			exec: function(editor:AceWrap) findFoldImpl(editor, true, true),
		});
		commands.addCommand({
			name: "selectPreviousFoldRegion",
			bindKey: wm("Ctrl-Shift-Up", "Command-Shift-Up"),
			exec: function(editor:AceWrap) findFoldImpl(editor, false, true),
		});
		commands.removeCommand("gotoline");
		commands.addCommand({
			name: "gotoline",
			bindKey: wm("Ctrl-G", "Command-G"),
			exec: function(editor:AceWrap) {
				AceWrap.loadModule("ace/ext/searchbox", function(e) {
					AceGotoLine.run(editor);
				});
			}
		});
	}
}
