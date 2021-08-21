package ui.preferences;
import electron.Electron;
import electron.FileWrap;
import js.html.Element;
import tools.HtmlTools;
import ui.Preferences.*;
import gml.GmlAPI;
import gml.Project;
import ui.RecentProjects;
import ui.preferences.PrefData;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class PrefNavTabs {
	public static function build(out:Element) {
		var el:Element;
		out = addGroup(out, "Tabs");
		out.dataset.outlineViewLabel = "Tabs";
		
		function syncOptions() {
			save();
			js.lib.Object.assign(ChromeTabs.impl.options, current.chromeTabs);
			ChromeTabs.impl.layoutTabs();
		}
		
		var cur = current.chromeTabs;
		addIntInput(out, "Minimum width", cur.minWidth, function(v) {
			current.chromeTabs.minWidth = v;
			syncOptions();
		});
		addIntInput(out, "Maximum width", cur.maxWidth, function(v) {
			current.chromeTabs.maxWidth = v;
			syncOptions();
		});
		
		el = addCheckbox(out, "Always use rectangular tabs", cur.boxyTabs, function(v) {
			current.chromeTabs.boxyTabs = v;
			syncOptions();
		});
		el.title = "Otherwise only uses rectangular tabs when multi-line";
		
		el = addCheckbox(out, "Auto-hide close buttons", cur.autoHideCloseButtons, function(v) {
			current.chromeTabs.autoHideCloseButtons = v;
			ChromeTabs.element.classList.setTokenFlag("chrome-tabs-auto-hide-close-buttons", v);
			ChromeTabs.impl.layoutTabs();
			save();
		});
		
		var sub = addGroup(out, "Multi-line tabs (breaks tab drag'n'drop)");
		addCheckbox(sub, "Enable", cur.multiline, function(v) {
			current.chromeTabs.multiline = v;
			syncOptions();
		});
		addCheckbox(sub, "Set tab widths based on content (further breaks DnD)", cur.fitText, function(v) {
			current.chromeTabs.fitText = v;
			ChromeTabs.element.classList.setTokenFlag("chrome-tabs-fit-text", v);
			syncOptions();
		});
		addCheckbox(sub, "Let the buttons flow around the system buttons", cur.flowAroundSystemButtons, function(v) {
			current.chromeTabs.flowAroundSystemButtons = v;
			syncOptions();
		});
	}
}