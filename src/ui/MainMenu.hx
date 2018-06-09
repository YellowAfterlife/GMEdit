package ui;
import electron.FileSystem;
import electron.Menu;
import electron.Dialog;
import electron.Electron;
import gml.Project;
import haxe.io.Path;
import tools.NativeString;
import yy.YyZip;

/**
 * That thing that shows up when you click on the triple-line icon next to project name.
 * @author YellowAfterlife
 */
class MainMenu {
	public static function init() {
		var menu = new Menu();
		#if (!lwedit)
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
		var exportItem = new MenuItem({ label: "Export project...",
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
					var url = tools.BufferTools.toObjectURL(zip, path, type);
					if (url != null) {
						var link = Main.document.createAnchorElement();
						link.href = url;
						link.download = path;
						Main.document.body.appendChild(link);
						link.click();
						
						// I'm not sure when exactly you are supposed to dealloc your URLs
						// if the user is going to be busy picking a save location meanwhile
						Main.window.setTimeout(function() {
							link.parentElement.removeChild(link);
							try {
								js.html.URL.revokeObjectURL(url);
							} catch (_:Dynamic) {
								//
							}
						}, 7000);
					}
				}
			}
		});
		menu.append(exportItem);
		menu.append(new MenuItem({ label: "Close project",
			click: function() gml.Project.open("")
		}));
		#else
		menu.append(new MenuItem({ label: "New project",
			click: function() {
				// todo
			}
		}));
		#end
		//
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
			var pj = Project.current;
			#if !lwedit
			exportItem.enabled = pj.version != none && Std.is(pj, YyZip);
			#end
			menu.popupAsync(e);
		});
	}
}
