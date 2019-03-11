package ace;
import ace.extern.AcePos;
import ace.extern.AceToken;
import electron.Clipboard;
import electron.Electron;
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
	public var editor:AceWrap;
	public function new() {
		menu = new Menu();
	}
	public function bind(editor:AceWrap) {
		this.editor = editor;
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
			var cmd = editor.commands.commandKeyBinding[k];
			k = k.charAt(0).toUpperCase() + k.substring(1);
			k = k.replaceExt(AceMacro.jsRx(~/-(\w)/g), function(_, c) {
				return "+" + c.toUpperCase();
			});
			commandAccels.set(cmd.name, k);
		}
		function cmdItem(cmd:String, label:String):MenuItem {
			return new MenuItem({
				accelerator: commandAccels[cmd],
				label: label,
				click: function() {
					editor.execCommand(cmd);
				}
			});
		}
		//
		var edit:Menu = new Menu();
		edit.append(cmdItem("duplicateSelection", "Duplicate selection"));
		menu.appendOpt({
			type: Sub,
			label: "Edit",
			submenu: edit,
		});
		//
		var search:Menu = new Menu();
		search.append(cmdItem("find", "Quick find"));
		search.append(cmdItem("replace", "Find and replace..."));
		search.appendOpt({
			label: "Global find and replace...",
			accelerator: "CommandOrControl+Shift+F",
			click: function() GlobalSearch.toggle()
		});
		search.append(cmdItem("gotoline", "Goto line..."));
		search.append(cmdItem("gotoPreviousFoldRegion", "Goto previous fold"));
		search.append(cmdItem("gotoNextFoldRegion", "Goto next fold"));
		menu.appendOpt({
			type: Sub,
			label: "Search",
			submenu: search,
		});
		//
		menu.appendSep();
		var findRefs = menu.appendOpt({
			label: "Open definition",
			accelerator: "F1",
			click: function() {
				OpenDeclaration.proc(editor.session, pos, tk);
			}
		});
		var findRefs = menu.appendOpt({
			label: "Find references",
			accelerator: "Shift+F1",
			click: function() {
				if (tk != null) GlobalSearch.findReferences(tk.value);
			}
		});
		//
		menu.appendSep();
		var undo = cmdItem("undo", "Undo");
		menu.append(undo);
		var redo = cmdItem("redo", "Redo");
		menu.append(redo);
		//
		if (Electron != null) {
			menu.appendSep();
			menu.appendOpt({
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
				label: "Paste",
				accelerator: "CommandOrControl+V",
				click: function() {
					editor.execCommand("paste", cb().readText());
				}
			});
		}
		//
		menu.appendSep();
		menu.append(cmdItem("selectall", "Select all"));
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
}
