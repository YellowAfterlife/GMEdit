package ui;
import electron.FileSystem;
import electron.Menu;
import electron.Dialog;
import electron.Electron;
import gml.Project;
import haxe.io.Path;
import tools.HtmlTools;
import tools.NativeString;
#if gmedit.live
import ui.liveweb.*;
import ui.miniweb.*;
#end
import ui.project.ProjectProperties;
import yy.zip.YyZip;
import Main.window;

/**
 * That thing that shows up when you click on the triple-line icon next to project name.
 * @author YellowAfterlife
 */
class MainMenu {
	static var menu:Menu;
	static var exportItem:MenuItem;
	static function addProjectItems(menu:Menu) {
		#if !gmedit.live
		if (Electron == null) {
			var form = Main.document.createFormElement();
			HtmlTools.moveOffScreen(form);
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
				id: "open-archive",
				click: function() {
					form.reset();
					input.click();
				}
			}));
			//
			if (yy.zip.YyZipDirectoryDialog.isAvailable())
			menu.append(new MenuItem({ label: "Open directory...",
				id: "open-directory",
				click: function() {
					yy.zip.YyZipDirectoryDialog.open();
				}
			}));
			//
		} else menu.append(new MenuItem({ label: "Open...",
			id: "open-dialog",
			icon: Menu.silkIcon("folder_page"),
			click: function() {
				var filters = gml.GmlVersion.hasCustomDialects ? [
					new DialogFilter("Anything supported", ["*"])
				] : [
					new DialogFilter("GameMaker files", ["gmx", "yy", "yyp", "yyz", "gml"]),
					new DialogFilter("Other common files", ["js", "md", "dmd", "txt", "ini"]),
					new DialogFilter("All files", ["*"])
				];
				Dialog.showOpenDialog({
					filters: filters,
				}, function(paths:Array<String>) {
					if (paths != null && paths[0] != null) {
						FileDrag.handle(paths[0], null);
					}
				});
			}
		}));
		menu.append(new MenuItem({
			id: "reload-project",
			label: "Reload project",
			icon: Menu.silkIcon("arrow_refresh"),
			accelerator: "CommandOrControl+R",
			click: function() gml.Project.current.reload()
		}));
		exportItem = new MenuItem({
			id: "export-project",
			label: "Export project...",
			icon: Menu.silkIcon("folder_go"),
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
		menu.append(new MenuItem({
			id: "close-project",
			label: "Close project",
			click: function() {
				gml.Project.open("");
				for (q in Main.document.querySelectorAll(".chrome-tab .chrome-tab-close")) {
					(cast q:js.html.Element).click();
				}
			}
		}));
		if (Electron != null) {
			menu.appendSep("sep-show-in-directory");
			menu.append(new MenuItem({
				id: "show-in-directory",
				label: "Show in directory",
				icon: Menu.silkIcon("show_in_directory"),
				click: function() {
					var pj = Project.current;
					var path = pj is YyZip ? (cast pj:YyZip).yyzPath : pj.path;
					electron.Shell.showItemInFolder(path);
				}
			}));
			menu.append(new MenuItem({
				id: "new-ide",
				label: "New IDE",
				icon: Menu.silkIcon("application_add"),
				click: function() electron.IPC.send("new-ide")
			}));
		}
		#end
	}
	#if (gmedit.live)
	static function addGMLiveWebItems(menu:Menu) {
		menu.append(new MenuItem({ label: "New tab",
			click: function() LiveWebTools.newTabDialog()
		}));
		menu.append(new MenuItem({ label: "New workspace",
			click: function() {
				var tabEls = ChromeTabs.impl.tabEls;
				if (tabEls.length > 0) {
					if (!window.confirm(
						"Are you sure you want to start a new workspace?" +
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
		#if gmedit.mini
		menu.appendSep("sep-run");
		menu.append(new MenuItem({ label: "Run",
			click: function() MiniWeb.run(),
		}));
		menu.append(new MenuItem({ label: "Stop",
			click: function() MiniWeb.stop(),
		}));
		#end
	}
	#end
	public static function init() {
		menu = new Menu();
		#if (!gmedit.live)
		addProjectItems(menu);
		#else
		addGMLiveWebItems(menu);
		#end
		//
		menu.appendSep("sep-help");
		#if !gmedit.mini
		menu.append(new MenuItem({
			id: "help",
			label: "Help",
			icon: Menu.silkIcon("help"),
			click: function() {
				var url:String = "https://github.com/GameMakerDiscord/GMEdit/wiki";
				#if gmedit.live
				url += '/GMLive.js';
				#end
				if (Electron != null) {
					electron.Shell.openExternal(url);
				} else window.open(url, "_blank");
			}
		}));
		#end
		menu.append(new MenuItem({
			id: "project-properties",
			label: ProjectProperties.name,
			icon: Menu.silkIcon("project_properties"),
			click: function() ProjectProperties.open()
		}));
		menu.append(new MenuItem({
			id: "preferences",
			label: "Preferences",
			icon: Menu.silkIcon("preferences"),
			click: function() Preferences.open()
		}));
		if (Electron != null && window.location.host == "") menu.append(new MenuItem({
			#if gmedit.live
			id: "switch-gmedit",
			label: "Switch to GMEdit",
			click: function() window.location.href = StringTools.replace(window.location.href, 
				"index-live.html", "index.html"),
			#else
			id: "switch-gmlive",
			label: "Switch to GMLive.js",
			click: function() window.location.href = StringTools.replace(window.location.href, 
				"index.html", "index-live.html"),
			#end
		}));
		if (Electron != null) menu.append(new MenuItem({
			id: "open-dev-tools",
			label: "Dev tools",
			accelerator: "CommandOrControl+Shift+I",
			click: function() {
				electron.extern.BrowserWindow.getFocusedWindow().toggleDevTools();
			}
		}));
		//
		var btn = Main.document.querySelector(".system-button.preferences");
		btn.addEventListener("click", function(e) {
			var pj = Project.current;
			#if !gmedit.live
			exportItem.enabled = pj.version != gml.GmlVersion.none && Std.is(pj, YyZip);
			#end
			menu.popupAsync(e);
		});
	}
}
