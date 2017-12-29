package ace;
import ace.AceWrap;

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
		commands.bindKey(wm("Ctrl-Enter", "Command-Enter"), "toggleFoldWidget");
		commands.bindKey(wm("Ctrl-M", "Command-M"), "foldall");
		commands.bindKey(wm("Ctrl-U", "Command-U"), "unfoldall");
		commands.bindKey(wm("Ctrl-Alt-Up", "Command-Alt-Up"), "movelinesup");
		commands.bindKey(wm("Ctrl-Alt-Down", "Command-Alt-Down"), "movelinesdown");
		commands.bindKey(wm("Alt-Shift-Up", "Alt-Shift-Up"), "addCursorAbove");
		commands.bindKey(wm("Alt-Shift-Down", "Alt-Shift-Down"), "addCursorBelow");
		commands.bindKey(wm("Ctrl-K", "Command-K"), "togglecomment");
		//
		inline function findFoldImpl(editor:AceWrap, fwd:Bool):Void {
			var session = editor.session;
			var foldWidgets = session.foldWidgets;
			var row = editor.selection.lead.row;
			var steps = fwd ? (session.getLength() - 1 - row) : row;
			var delta = fwd ? 1 : -1;
			while (--steps >= 0) {
				row += delta;
				if (foldWidgets[row] == null) {
					foldWidgets[row] = session.getFoldWidget(row);
				}
				if (foldWidgets[row] != "start") continue;
				if (session.getFoldAt(row, 0) != null) continue;
				editor.gotoLine(row + 1, session.getLine(row).length);
				break;
			}
		}
		commands.addCommand({
			name: "nextFoldWidget",
			bindKey: wm("Ctrl-Down", "Command-Down"),
			exec: function(editor:AceWrap) {
				findFoldImpl(editor, true);
			}
		});
		commands.addCommand({
			name: "previousFoldWidget",
			bindKey: wm("Ctrl-Up", "Command-Up"),
			exec: function(editor:AceWrap) {
				findFoldImpl(editor, false);
			}
		});
	}
}
