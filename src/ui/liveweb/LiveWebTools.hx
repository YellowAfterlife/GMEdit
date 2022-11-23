package ui.liveweb;
import ace.extern.AceRange;
import gml.file.GmlFile;
import parsers.GmlSeeker;
import ui.liveweb.LiveWebAPI.LiveWebError;
import Main.window;
using tools.HtmlTools;

/**
 * ...
 * @author 
 */
class LiveWebTools {
	public static function addTab(name:String, code:String) {
		for (tab in ChromeTabs.impl.tabEls) {
			if (tab.gmlFile.name == name) {
				Main.window.alert("A tab with this name already exists.");
				return;
			}
		}
		var file = new GmlFile(name, name, KLiveWeb.inst, code);
		GmlFile.openTab(file);
		GmlSeeker.runSync(name, name, code, KLiveWeb.inst);
	}
	
	public static function newTabDialog() {
		electron.Dialog.showPrompt("New tab name?", "", function(name) {
			if (name == null || name == "") return;
			addTab(name, "");
		});
	}
	
	public static function showError(e:LiveWebError) {
		var path = e.file;
		var col = e.column;
		var row = e.row;
		var msg = e.text;
		//
		var hint = Main.aceEditor.statusBar.statusHint;
		hint.setInnerText(msg);
		hint.classList.add("active");
		hint.onclick = function(_) {
			if (GmlFile.current.path != path) {
				for (tab in ChromeTabs.impl.tabEls) {
					if (tab.gmlFile.path != path) continue;
					tab.click();
					break;
				}
				window.setTimeout(function() {
					Main.aceEditor.gotoLine0(row, col);
				});
			} else Main.aceEditor.gotoLine0(row, col);
		};
		var statusBar = Main.aceEditor.statusBar;
		statusBar.ignoreUntil = window.performance.now() + statusBar.delayTime + 50;
		//
		for (tab in ChromeTabs.impl.tabEls) {
			if (tab.gmlFile.path != path) continue;
			var session = tab.gmlFile.getAceSession();
			if (session == null) continue;
			var range = new AceRange(0, row, session.getLine(row).length, row);
			session.gmlErrorMarker = session.addMarker(range, "ace_error-line", "fullLine");
			session.setAnnotations([{
				row: row, column: col, type: "error", text: msg
			}]);
			break;
		}
	}
}