package ui;
import electron.FileSystem;
import electron.Menu;
import electron.Dialog;
import electron.Electron;

/**
 * That thing that shows up when you click on the triple-line icon next to project name.
 * @author YellowAfterlife
 */
class MainMenu {
	public static function init() {
		var menu = new Menu();
		#if (!lwedit)
		menu.append(new MenuItem({ label: "Open...",
			click: function() {
				var paths = Dialog.showOpenDialog({
					filters: [
						new DialogFilter("GameMaker files", ["gmx", "yy", "yyp", "gml"]),
						new DialogFilter("All files", ["*"]),
					],
				});
				if (paths != null && paths[0] != null) {
					FileDrag.handle(paths[0], null);
				}
			}
		}));
		menu.append(new MenuItem({ label: "Reload project",
			accelerator: "CommandOrControl+R",
			click: function() gml.Project.current.reload()
		}));
		menu.append(new MenuItem({ label: "Close project",
			click: function() gml.Project.open("")
		}));
		#else
		menu.append(new MenuItem({ label: "New project",
			click: function() {
				
			}
		});
		#end
		menu.append(new MenuItem({ type: Sep }));
		menu.append(new MenuItem({ label: "Preferences",
			click: function() Preferences.open()
		}));
		if (Electron != null) menu.append(new MenuItem({ label: "Dev tools",
			accelerator: "CommandOrControl+Shift+I",
			click: function() {
				Electron.remote.BrowserWindow.getFocusedWindow().toggleDevTools();
			}
		}));
		//
		var btn = Main.document.querySelector(".system-button.preferences");
		btn.addEventListener("click", function(e) {
			menu.popupAsync(e);
		});
	}
}
