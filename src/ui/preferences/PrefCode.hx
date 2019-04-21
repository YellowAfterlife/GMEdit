package ui.preferences;
import js.html.Element;
import ui.Preferences.*;
import gml.GmlAPI;
import gml.file.GmlFile;
using tools.HtmlTools;
import js.html.SelectElement;
import file.kind.misc.KSnippets;

/**
 * ...
 * @author YellowAfterlife
 */
class PrefCode {
	public static function build(out:Element) {
		out = addGroup(out, "Code editor");
		out.id = "pref-code";
		var el:Element;
		//
		addCheckbox(out, "UK spelling", current.ukSpelling, function(z) {
			current.ukSpelling = z;
			GmlAPI.ukSpelling = z;
			GmlAPI.init();
			save();
		}).title = "Displays UK versions of function/variable names (e.g. draw_set_colour) in auto-completion when available.";
		//
		var compMatchModes = [
			"Start of string (GMS1 style)",
			"Containing (GMS2 style)",
			"Smart (`icl` -> `io_clear`)",
			"Per-section (`icl` -> `instance_create_layer`)",
		];
		el = addDropdown(out, "Auto-completion mode", compMatchModes[current.compMatchMode], compMatchModes, function(s) {
			current.compMatchMode = compMatchModes.indexOf(s);
			save();
		});
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Preferences#auto-completion-mode");
		//
		addCheckbox(out, "Auto-detect soft tabs", current.detectTab, function(z) {
			current.detectTab = z;
			save();
		}).title = "If enabled, will auto-detect whether to indent with tabs or spaces"
			+ " based on whether the file has lines starting with either.";
		//
		var tooltipKinds = ["None", "Custom"];
		addDropdown(out, "Code tooltips", tooltipKinds[current.tooltipKind], tooltipKinds, function(s) {
			current.tooltipKind = tooltipKinds.indexOf(s);
			save();
		});
		addIntInput(out, "Code tooltip delay (ms):", current.tooltipDelay, function(t) {
			current.tooltipDelay = t;
			save();
		});
		//
		var optSnippets_0 = ["gml", "gml_search", "shader"];
		var optSnippets_1 = ["GML", "Search results", "Shaders"];
		var optSnippets_select:SelectElement = null;
		el = addDropdown(out, "Edit snippets", "", optSnippets_1, function(name) {
			var mode = optSnippets_0[optSnippets_1.indexOf(name)];
			GmlFile.openTab(new GmlFile(mode + ".snippets", mode, KSnippets.inst));
			optSnippets_select.value = "";
		});
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-snippets");
		optSnippets_select = el.querySelectorAuto("select");
		//
		addButton(out, "Code Editor Settings", function() {
			ace.AceWrap.loadModule("ace/ext/settings_menu", function(module) {
				module.init(Main.aceEditor);
				untyped Main.aceEditor.showSettingsMenu();
			});
		});
	}
}
