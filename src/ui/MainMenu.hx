package ui;
import electron.FileSystem;
import electron.Menu;
import electron.Dialog;

/**
 * That thing that shows up when you click on the triple-line icon next to project name.
 * @author YellowAfterlife
 */
class MainMenu {
	public static function init() {
		var menu = new Menu();
		menu.append(new MenuItem({
			label: "Open...",
			click: function() {
				var paths = Dialog.showOpenDialog({
					filters: [
						new DialogFilter("GameMaker files", ["gmx", "yy", "yyp", "gml"]),
						new DialogFilter("All files", ["*"]),
					],
				});
				if (paths != null && paths[0] != null) {
					FileDrag.handle(paths[0]);
				}
			}
		}));
		menu.append(new MenuItem({
			label: "Reload project",
			accelerator: "CommandOrControl+R",
			click: function() gml.Project.current.reload()
		}));
		menu.append(new MenuItem({
			label: "Close project",
			click: function() gml.Project.open("")
		}));
		menu.append(new MenuItem({ type: Sep }));
		menu.append(new MenuItem({
			label: "Preferences",
			click: function() Preferences.open()
		}));
		menu.append(new MenuItem({
			label: "Dev tools",
			accelerator: "CommandOrControl+Shift+I",
			click: function() {
				electron.Electron.remote.BrowserWindow.getFocusedWindow().toggleDevTools();
			}
		}));
		//
		var btn = Main.document.querySelector(".system-button.preferences");
		btn.addEventListener("click", function(_) {
			menu.popupAsync();
		});
	}
}
