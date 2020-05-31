package ace;
import ace.AceWrap;
import ace.extern.*;
import ace.extern.AceCommandManager;
import haxe.extern.EitherType;
import js.lib.RegExp;
import tools.CharCode;
import tools.NativeString;
import ui.CommandPalette;
using StringTools;

/**
 * GMS-style keybinds, as per
 * https://docs2.yoyogames.com/source/_build/1_overview/2_quick_start/8_shortcuts.html
 * @author YellowAfterlife
 */
@:expose("AceCommands")
@:keep class AceCommands {
	
	/** adds a command to the code editor(s) */
	@:doc public static function add(command:AceCommand) {
		Main.aceEditor.commands.addCommand(command);
	}
	
	static function getKeybindString(editor:AceWrap, cmdName:String, ?kb:AceCommandKey):Null<String> {
		var cmd = editor.commands.commands[cmdName];
		if (cmd == null) return null;
		var key:String = null;
		if (kb == null) kb = cmd.bindKey;
		if (kb == null) {
			var ckb = editor.commands.commandKeyBinding;
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
		return key;
	}
	
	/**
	 * Takes a command where "exec" is an Ace command name,
	 * modifies it to call editor.execCommand instead,
	 * sets keybind field (if not specified yet),
	 * and adds it to command palette.
	 * NB! The input command is modified in process.
	 */
	@:doc public static function addToPalette(cmd:CommandDef):Void {
		var cmdName:String = cast cmd.exec;
		var editor = Main.aceEditor;
		if (!Std.is(cmdName, String)) throw "Expected cmd.exec to be command name";
		if (cmd.key == null) cmd.key = getKeybindString(editor, cmdName);
		cmd.exec = function() editor.execCommand(cmdName);
		CommandPalette.add(cmd);
	}
	
	/** Removes a command from the editor(s) */
	@:doc public static function remove(command:EitherType<AceCommand, String>) {
		Main.aceEditor.commands.removeCommand(command);
	}
	
	/** Is here purely for complete-ness */
	@:doc public static function removeFromPalette(cmd:CommandDef) {
		CommandPalette.remove(cmd);
	}
	
	public static function init(editor:AceWrap, isPrimary:Bool) {
		var commands = editor.commands;
		inline function wm(win:String, mac:String):AceCommandKey {
			return { win: win, mac: mac };
		}
		/// displays the given command in Ctrl+T>
		function show(cmdName:String, text:String, ?kb:AceCommandKey) {
			if (!isPrimary) return;
			var cmd = editor.commands.commands[cmdName];
			if (cmd == null) Main.console.warn('Command $cmdName is amiss');
			var key:String = getKeybindString(editor, cmdName, kb);
			CommandPalette.add({
				name: text,
				exec: function() editor.execCommand(cmdName),
				key: key,
			});
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
			name: "openDeclaration",
			bindKey: "F1|F12",
			exec: function(editor:AceWrap) {
				var pos = editor.getCursorPosition();
				var line = editor.session.getLine(pos.row);
				var col = pos.column;
				if (CharCode.at(line, col).isIdent1_ni()
					&& !CharCode.at(line, col - 1).isIdent1_ni()
				) pos.column++;
				var tk = editor.session.getTokenAtPos(pos);
				ui.OpenDeclaration.proc(editor.session, pos, tk);
			}
		});
		add({
			name: "findReferences",
			bindKey: "Shift-F1|Shift-F12",
			exec: function(editor:AceWrap) {
				var pos = editor.getCursorPosition();
				var line = editor.session.getLine(pos.row);
				var col = pos.column;
				if (CharCode.at(line, col).isIdent1_ni()
					&& !CharCode.at(line, col - 1).isIdent1_ni()
				) pos.column++;
				var tk = editor.session.getTokenAtPos(pos);
				if (tk != null) ui.GlobalSearch.findReferences(tk.value);
			}
		});
		add({
			name: "saveFile",
			bindKey: wm("Ctrl-S", "Command-S"),
			exec: function(editor:AceWrap) {
				var file = editor.session.gmlFile;
				if (file == null) return;
				file.save();
			}
		});
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
		bind(wm("Ctrl-D", "Command-D"), "duplicateSelection");
		bind(wm("Ctrl-Shift-D", "Command-Shift-D"), "removeline");
		//
		var findRxs = "^#define\\b|^#event\\b|^#moment\\b|^#section\\b";
		var findRx0 = new RegExp('(?:$findRxs|#region\\b|//{|//#region\\b|//#mark\\b)');
		//var findRx1 = new RegExp('(?:$findRxs)');
		function findFoldImpl(editor:AceWrap, fwd:Bool, select:Bool):Void {
			var session = editor.session;
			var row = editor.selection.lead.row;
			var steps = fwd ? (session.getLength() - 1 - row) : row;
			var delta = fwd ? 1 : -1;
			var rx = findRx0;
			while (--steps >= 0) {
				row += delta;
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
		show("showSettingsMenu", "Code editor preferences");
	}
}
