package ace;
import ace.AceWrap;
import ace.extern.*;
import ace.extern.AceCommandManager;
import haxe.extern.EitherType;
import js.RegExp;
import tools.NativeString;
import ui.GlobalCommands;

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
		/// displays the given command in Ctrl+T>
		function show(cmdName:String, text:String, ?kb:AceCommandKey) {
			var cmd = Main.aceEditor.commands.commands[cmdName];
			var key:String = null;
			if (cmd != null) {
				//
				if (kb == null) kb = cmd.bindKey;
				if (kb == null) {
					var ckb = Main.aceEditor.commands.commandKeyBinding;
					for (k in ckb.keys()) {
						var ckv = ckb[k];
						if (ckv == cmd || (cast ckv) == cmdName) { key = k; break; } 
					}
				}
				if (kb == null || key != null) {
					// OK!
				} else if (Std.is(kb, String)) {
					key = kb;
				} else {
					if (electron.FileWrap.isMac) {
						key = (kb:AceCommandKeyPair).mac;
					} else key = (kb:AceCommandKeyPair).win;
				}
				if (key != null) {
					var p = key.indexOf("|");
					if (p >= 0) key = key.substring(0, p);
					key = NativeString.replaceExt(key,
						new RegExp("(?:^|\\b)(\\w)", "g"),
						(_, c) -> c.toUpperCase());
				}
			} else Main.console.warn('Command $cmdName is amiss');
			GlobalCommands.add(text, function() {
				Main.aceEditor.execCommand(cmdName);
			}, key);
		}
		function add(cmd:AceCommand, ?showAs:String) {
			commands.addCommand(cmd);
			if (showAs != null) show(cmd.name, showAs);
		}
		function bind(key:AceCommandKey, cmd:String, ?showAs:String) {
			commands.bindKey(key, cmd);
			if (showAs != null) show(cmd, showAs, key);
		}
		add({
			name: "startAutocomplete",
			exec: function(editor:AceWrap) {
				if (editor.completer != null) {
					editor.completer.showPopup(editor);
				}
			},
			bindKey: "Ctrl-Space|Ctrl-Shift-Space|Alt-Space"
		});
		add({
			name: "showKeyboardShortcuts",
			bindKey: wm("Ctrl-Alt-h", "Command-Alt-h"),
			exec: function(editor) {
				AceWrap.loadModule("ace/ext/keybinding_menu", function(module) {
					module.init(editor);
					untyped editor.showKeyboardShortcuts();
				});
			}
		}, "Show keyboard mappings");
		#if lwedit
		add({
			name: "lw_execute",
			bindKey: {win: "Ctrl-Enter", mac: "Command-Enter|Ctrl-Enter"},
			exec: function(editor) {
				Main.document.getElementById("refresh").click();
			}
		}, "Run game");
		#else
		bind(wm("Ctrl-Enter", "Command-Enter"), "toggleFoldWidget");
		#end
		bind(wm("Ctrl-M", "Command-M"), "foldall", "Fold All");
		bind(wm("Ctrl-U", "Command-U"), "unfoldall", "Unfold All");
		bind(wm("Ctrl-Alt-Up", "Command-Alt-Up"), "movelinesup");
		bind(wm("Ctrl-Alt-Down", "Command-Alt-Down"), "movelinesdown");
		bind(wm("Alt-Shift-Up", "Alt-Shift-Up"), "addCursorAbove");
		bind(wm("Alt-Shift-Down", "Alt-Shift-Down"), "addCursorBelow");
		bind(wm("Ctrl-K", "Command-K"), "togglecomment");
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
		add({
			name: "gotoNextFoldRegion",
			bindKey: wm("Ctrl-Down", "Command-Down"),
			exec: function(editor:AceWrap) findFoldImpl(editor, true, false),
		}, "Next fold region");
		add({
			name: "gotoPreviousFoldRegion",
			bindKey: wm("Ctrl-Up", "Command-Up"),
			exec: function(editor:AceWrap) findFoldImpl(editor, false, false),
		}, "Previous fold region");
		add({
			name: "selectNextFoldRegion",
			bindKey: wm("Ctrl-Shift-Down", "Command-Shift-Down"),
			exec: function(editor:AceWrap) findFoldImpl(editor, true, true),
		});
		add({
			name: "selectPreviousFoldRegion",
			bindKey: wm("Ctrl-Shift-Up", "Command-Shift-Up"),
			exec: function(editor:AceWrap) findFoldImpl(editor, false, true),
		});
		commands.removeCommand("gotoline");
		add({
			name: "gotoline",
			bindKey: wm("Ctrl-G", "Command-G"),
			exec: function(editor:AceWrap) {
				AceWrap.loadModule("ace/ext/searchbox", function(e) {
					AceGotoLine.run(editor);
				});
			}
		}, "Go to line...");
		//
		add({
			name: "genEnumNames",
			exec: function(editor:AceWrap) {
				ace.plugins.AceEnumNames.run(editor, false);
			}
		}, "Macro: Generate enum names");
		add({
			name: "genEnumLookup",
			exec: function(editor:AceWrap) {
				ace.plugins.AceEnumNames.run(editor, true);
			}
		}, "Macro: Generate enum lookup");
		//
		show("showSettingsMenu", "Code editor preferences");
	}
}
