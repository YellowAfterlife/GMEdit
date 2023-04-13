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
		var pos:AcePos = null;
		var tk:AceToken = null;
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
		function cmdItem(cmd:String, label:String, ?silkIcon:String):MenuItem {
			var icon = silkIcon != null ? Menu.silkIcon(silkIcon) : null;
			var item = new MenuItem({
				id: cmd,
				accelerator: commandAccels[cmd],
				label: label,
				icon: icon,
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
		search.append(cmdItem("find", "Quick find", "page_white_find"));
		search.append(cmdItem("replace", "Find and replace...", "magnifier"));
		search.appendOpt({
			id: "global-search",
			label: "Global find and replace...",
			icon: Menu.silkIcon("folder_explore"),
			accelerator: "CommandOrControl+Shift+F",
			click: function() GlobalSearch.toggle()
		});
		search.append(cmdItem("gotoline", "Goto line...", "arrow_right"));
		search.append(cmdItem("gotoPreviousFoldRegion", "Goto previous fold", "arrow_up"));
		search.append(cmdItem("gotoNextFoldRegion", "Goto next fold", "arrow_down"));
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
			icon: Menu.silkIcon("brick_go"),
			accelerator: "F1",
			click: function() {
				autofixToken();
				if (tk != null) OpenDeclaration.proc(editor.session, pos, tk);
			}
		});
		var findRefs = menu.appendOpt({
			id: "find-references",
			label: "Find references",
			icon: Menu.silkIcon("find_references"),
			accelerator: "Shift+F1",
			click: function() {
				autofixToken();
				if (tk != null) GlobalSearch.findReferences(tk.value);
			}
		});
		//
		menu.appendSep("sep-history");
		var undo = cmdItem("undo", "Undo", "arrow_undo");
		menu.append(undo);
		var redo = cmdItem("redo", "Redo", "arrow_redo");
		menu.append(redo);
		//
		if (Electron != null) {
			menu.appendSep("sep-clipboard");
			menu.appendOpt({
				id: "cut",
				label: "Cut",
				role: "cut",
				icon: Menu.silkIcon("cut"),
				accelerator: "CommandOrControl+X",
				click: function() { // used in web
					if (!editor.selection.isEmpty()) {
						cb().writeText(editor.getSelectedText());
					}
					editor.execCommand("cut");
				}
			});
			menu.appendOpt({
				id: "copy",
				label: "Copy",
				role: "copy",
				icon: Menu.silkIcon("page_copy"),
				accelerator: "CommandOrControl+C",
				click: function() { // used in web
					if (!editor.selection.isEmpty()) {
						cb().writeText(editor.getSelectedText());
					}
					editor.execCommand("copy");
				}
			});
			menu.appendOpt({
				id: "paste",
				label: "Paste",
				role: "paste",
				icon: Menu.silkIcon("page_paste"),
				accelerator: "CommandOrControl+V",
				click: function() { // used in web
					editor.execCommand("paste", cb().readText());
				}
			});
		}
		//
		menu.appendSep("sep-select");
		menu.append(cmdItem("selectall", "Select all"));
		//
		editor.container.addEventListener("contextmenu", function(ev) {
			ev.preventDefault();
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
