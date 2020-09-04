package ace;
import ace.extern.AcePos;
import ace.extern.AceToken;
import electron.Clipboard;
import electron.Electron;
import electron.FileWrap;
import electron.Menu;
import js.Promise;
import tools.Dictionary;
import ui.GlobalSearch;
import ui.OpenDeclaration;
using tools.NativeString;

/**
 * The context menu that pops up when you right-click the code editor
 * @author YellowAfterlife
 */
class AceCtxMenu {
	public var menu:Menu;
	public var editMenu:Menu;
	public var searchMenu:Menu;
	public var editor:AceWrap;
	public function new() {
		menu = new Menu();
	}
	public function bind(editor:AceWrap) {
		this.editor = editor;
		editor.contextMenu = this;
		var pos:AcePos;
		var tk:AceToken;
		inline function cb():Clipboard {
			return Electron.clipboard;
		}
		function getAccel(cmd:String):String {
			try {
				return editor.commands.commands[cmd].getAccelerator();
			} catch (x:Dynamic) {
				Main.console.log('Error retrieving accelerator for $cmd:', x);
				return null;
			}
		}
		var commandAccels = new Dictionary<String>();
		for (k in editor.commands.commandKeyBinding.keys()) {
			k = k.charAt(0).toUpperCase() + k.substring(1);
			k = k.replaceExt(AceMacro.jsRx(~/-(\w)/g), function(_, c) {
				return "+" + c.toUpperCase();
			});
			for (cmdName in editor.commands.getCommandNamesForKeybinding(k)) {
				commandAccels.set(cmdName, k);
			}
		}
		function cmdItem(cmd:String, label:String):MenuItem {
			var item = new MenuItem({
				id: cmd,
				accelerator: commandAccels[cmd],
				label: label,
				click: function() {
					editor.execCommand(cmd);
				}
			});
			(item:Dynamic).aceCommand = cmd;
			return item;
		}
		//
		var edit:Menu = editMenu = new Menu();
		edit.append(cmdItem("duplicateSelection", "Duplicate selection"));
		menu.appendOpt({
			id: "sub-edit",
			type: Sub,
			label: "Edit",
			submenu: edit,
		});
		//
		var search:Menu = searchMenu = new Menu();
		search.append(cmdItem("find", "Quick find"));
		search.append(cmdItem("replace", "Find and replace..."));
		search.appendOpt({
			id: "global-search",
			label: "Global find and replace...",
			accelerator: "CommandOrControl+Shift+F",
			click: function() GlobalSearch.toggle()
		});
		search.append(cmdItem("gotoline", "Goto line..."));
		search.append(cmdItem("gotoPreviousFoldRegion", "Goto previous fold"));
		search.append(cmdItem("gotoNextFoldRegion", "Goto next fold"));
		menu.appendOpt({
			id: "sub-search",
			type: Sub,
			label: "Search",
			submenu: search,
		});
		//
		menu.appendSep("sep-definition");
		function autofixToken() {
			if (tk == null) return;
			if (tk.value.trimBoth() != "") return;
			pos.column++;
			tk = editor.session.getTokenAtPos(pos);
			if (tk.value.trimBoth() == "") tk = null;
		}
		var findRefs = menu.appendOpt({
			id: "open-definition",
			label: "Open definition",
			accelerator: "F1",
			click: function() {
				autofixToken();
				if (tk != null) OpenDeclaration.proc(editor.session, pos, tk);
			}
		});
		var findRefs = menu.appendOpt({
			id: "find-references",
			label: "Find references",
			accelerator: "Shift+F1",
			click: function() {
				autofixToken();
				if (tk != null) GlobalSearch.findReferences(tk.value);
			}
		});
		//
		menu.appendSep("sep-history");
		var undo = cmdItem("undo", "Undo");
		menu.append(undo);
		var redo = cmdItem("redo", "Redo");
		menu.append(redo);
		//
		if (Electron != null) {
			menu.appendSep("sep-clipboard");
			menu.appendOpt({
				id: "cut",
				label: "Cut",
				accelerator: "CommandOrControl+X",
				click: function() {
					if (!editor.selection.isEmpty()) {
						cb().writeText(editor.getSelectedText());
					}
					editor.execCommand("cut");
				}
			});
			menu.appendOpt({
				id: "copy",
				label: "Copy",
				accelerator: "CommandOrControl+C",
				click: function() {
					if (!editor.selection.isEmpty()) {
						cb().writeText(editor.getSelectedText());
					}
					editor.execCommand("copy");
				}
			});
			menu.appendOpt({
				id: "paste",
				label: "Paste",
				accelerator: "CommandOrControl+V",
				click: function() {
					editor.execCommand("paste", cb().readText());
				}
			});
		}
		//
		menu.appendSep("sep-select");
		menu.append(cmdItem("selectall", "Select all"));
		//
		editor.container.addEventListener("contextmenu", function(ev) {
			pos = editor.getCursorPosition();
			tk = editor.session.getTokenAtPos(pos);
			var um = editor.session.getUndoManager();
			undo.enabled = um.hasUndo();
			redo.enabled = um.hasRedo();
			menu.popupAsync(ev);
			return false;
		});
	}
	public static function initMac(editor:AceWrap) {
		// Mac wants a menu, or you shall not be able to use Cmd+C/Cmd+V
		// So we'll bind the one attached to main code editor, whatever
		if (Electron == null || !FileWrap.isMac) return;
		var menu = new Menu();
		menu.appendOpt({
			id: "sub-edit",
			label: "Edit",
			submenu: editor.contextMenu.menu,
		});
		Menu.setApplicationMenu(menu);
	}
}
