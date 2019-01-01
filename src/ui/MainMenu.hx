package ui;
import electron.FileSystem;
import electron.Menu;
import electron.Dialog;
import electron.Electron;
import gml.Project;
import haxe.io.Path;
import tools.NativeString;
import ui.liveweb.*;
import yy.YyZip;
import Main.window;

/**
 * That thing that shows up when you click on the triple-line icon next to project name.
 * @author YellowAfterlife
 */
class MainMenu {
	static var exportItem:MenuItem;
	static function addProjectItems(menu:Menu) {
		#if !lwedit
		if (Electron == null) {
			var form = Main.document.createFormElement();
			var input = Main.document.createInputElement();
			input.type = "file";
			input.accept = ".zip,.yyz";
			input.onchange = function(_) {
				var file = input.files[0];
				if (file == null) return;
				FileDrag.handle(file.name, file);
			};
			form.appendChild(input);
			Main.document.body.appendChild(form);
			menu.append(new MenuItem({ label: "Open archive...",
				click: function() {
					form.reset();
					input.click();
				}
			}));
			//
			menu.append(new MenuItem({ label: "Open directory...",
				click: function() {
					YyZip.directoryDialog();
				}
			}));
			//
		} else menu.append(new MenuItem({ label: "Open...",
			click: function() {
				Dialog.showOpenDialog({
					filters: [
						new DialogFilter("GameMaker files", ["gmx", "yy", "yyp", "yyz", "gml"]),
						new DialogFilter("All files", ["*"]),
					],
				}, function(paths:Array<String>) {
					if (paths != null && paths[0] != null) {
						FileDrag.handle(paths[0], null);
					}
				});
			}
		}));
		menu.append(new MenuItem({ label: "Reload project",
			accelerator: "CommandOrControl+R",
			click: function() gml.Project.current.reload()
		}));
		exportItem = new MenuItem({ label: "Export project...",
			click: function() {
				var pj = Project.current;
				var yyz:YyZip = cast pj;
				var zip = yyz.toZip();
				if (Electron != null) {
					
				} else {
					var path = pj.displayName, type;
					if (pj.version == gml.GmlVersion.v2) {
						path += ".yyz";
						type = "application/octet-stream";
					} else {
						path += ".zip";
						type = "application/zip";
					}
					//
					tools.BufferTools.saveAs(zip, path, type);
				}
			}
		});
		menu.append(exportItem);
		menu.append(new MenuItem({ label: "Close project",
			click: function() {
				gml.Project.open("");
				for (q in Main.document.querySelectorAll(".chrome-tab .chrome-tab-close")) {
					(cast q:js.html.Element).click();
				}
			}
		}));
		if (Electron != null) {
			menu.append(new MenuItem({ type: Sep }));
			menu.append(new MenuItem({ label: "Show in directory",
				click: function() electron.Shell.showItemInFolder(Project.current.path)
			}));
		}
		#end
	}
	static function addGMLiveWebItems(menu:Menu) {
		#if lwedit
		menu.append(new MenuItem({ label: "New tab",
			click: function() LiveWeb.newTabDialog()
		}));
		menu.append(new MenuItem({ label: "New project",
			click: function() {
				var tabEls = ChromeTabs.impl.tabEls;
				if (tabEls.length > 0) {
					if (!window.confirm(
						"Are you sure you want to start a new project?" +
						"\nAll tabs will be closed."
					)) return;
					var i = tabEls.length;
					while (--i >= 0) {
						var tab = tabEls[i];
						tab.classList.add("chrome-tab-force-close");
						tab.querySelector(".chrome-tab-close").click();
					}
				}
			}
		}));
		menu.append(new MenuItem({ label: "Import...",
			click: function() LiveWebIO.importDialog()
		}));
		menu.append(new MenuItem({ label: "Export...",
			click: function() LiveWebIO.exportDialog()
		}));
		#end
	}
	public static function init() {
		var menu = new Menu();
		#if (!lwedit)
		addProjectItems(menu);
		#else
		addGMLiveWebItems(menu);
		#end
		//
		menu.append(new MenuItem({ type: Sep }));
		menu.append(new MenuItem({ label: "Help",
			click: function() {
				var url:String = "https://github.com/GameMakerDiscord/GMEdit/wiki";
				#if lwedit
				url += '/GMLive.js';
				#end
				if (Electron != null) {
					electron.Shell.openExternal(url);
				} else window.open(url, "_blank");
			}
		}));
		menu.append(new MenuItem({ label: "Preferences",
			click: function() Preferences.open()
		}));
		if (Electron != null && window.location.host == "") menu.append(new MenuItem({
			#if lwedit
			label: "Switch to GMEdit",
			click: function() window.location.href = StringTools.replace(window.location.href, 
				"index-live.html", "index.html"),
			#else
			label: "Switch to GMLive.js",
			click: function() window.location.href = StringTools.replace(window.location.href, 
				"index.html", "index-live.html"),
			#end
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
			var pj = Project.current;
			#if !lwedit
			exportItem.enabled = pj.version != none && Std.is(pj, YyZip);
			#end
			menu.popupAsync(e);
		});
	}
}
