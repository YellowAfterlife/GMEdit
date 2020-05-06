package ui.project;
import gml.GmlAPI;
import haxe.Json;
import js.html.DivElement;
import js.html.Element;
import gml.Project;
import file.kind.misc.KProjectProperties;
import js.html.FieldSetElement;
import js.html.InputElement;
import js.lib.RegExp;
import tools.Dictionary;
import tools.NativeObject;
import tools.JsTools.or;
import tools.JsTools.orx;
import electron.FileWrap;
import tools.NativeString;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class ProjectProperties {
	public static function load(project:Project):ProjectData {
		//
		var def:ProjectData = {
			
		};
		if (project.path == "") return def;
		//
		var data:ProjectData = project.readConfigJsonFileSync("properties.json");
		if (data == null) {
			data = def;
		} else NativeObject.forField(def, function(k) {
			if (Reflect.field(data, k) == null) {
				Reflect.setField(data, k, Reflect.field(def, k));
			}
		});
		//
		return data;
	}
	public static function save(project:Project, data:ProjectData) {
		project.writeConfigJsonFileSync("properties.json", data);
	}
	
	static function buildCode(project:Project, out:DivElement) {
		var d = project.properties;
		var fs = Preferences.addGroup(out, "Code editor (these take effect for newly opened editors)");
		var el = Preferences.addInput(fs, "Indentation size override",
			(d.indentSize != null ? "" + d.indentSize : ""),
		function(s) {
			d.indentSize = Std.parseInt(s);
			save(project, d);
		});
		el.title = "Blank for default";
		//
		var indentModes = ["default", "tabs", "spaces"];
		Preferences.addRadios(fs, "Indentation mode override", indentModes[
			d.indentWithTabs == null ? 0 : (d.indentWithTabs ? 1 : 2)
		], indentModes, function(v) {
			d.indentWithTabs = v == indentModes[0] ? null : v == indentModes[1];
			save(project, d);
		});
		//
		var newLineModeDef = "auto-detect";
		var newLineModes = [newLineModeDef, "windows", "unix"];
		Preferences.addDropdown(fs, "New line mode override",
			d.newLineMode != null ? d.newLineMode : newLineModeDef,
		newLineModes, function(s) {
			if (s == newLineModeDef) s = null;
			d.newLineMode = s;
			save(project, d);
		});
	}
	
	static function buildSyntax(project:Project, out:DivElement) {
		var d = project.properties;
		var fs = Preferences.addGroup(out, "Syntax extensions");
		var lambdaModes = [
			"Default (extension)",
			"Compatible (extension macros)",
			"Scripts (GMS2 only)",
		];
		var el:Element = Preferences.addRadios(fs, "#lambda mode",
			lambdaModes[or(d.lambdaMode, Default)], lambdaModes,
		function(s) {
			d.lambdaMode = lambdaModes.indexOf(s);
			save(project, d);
		});
		if (project.version.config.projectModeId != 2) {
			el.querySelectorAuto("label:last-of-type input", InputElement).disabled = true;
		}
		
		//
		var argRegexInput:InputElement;
		el = Preferences.addInput(fs,
			"Regex for trimming argument name (e.g. `^_(\\w+)$`)",
			or(d.argNameRegex, ""),
		function(s) {
			if (NativeString.trimBoth(s) == "") s = null;
			if (s != null) try {
				new RegExp(s);
				argRegexInput.classList.remove("error");
			} catch (x:Dynamic) {
				argRegexInput.classList.add("error");
				electron.Dialog.showError("Invalid regexp: " + x);
				return;
			}
			d.argNameRegex = s;
			save(project, d);
		});
		argRegexInput = el.querySelectorAuto("input");
		
		//
		var templateStringInput:InputElement;
		el = Preferences.addInput(fs,
			"Template string script name",
			or(d.templateStringScript, ""),
		function(s) {
			s = NativeString.trimBoth(s);
			if (s == "") s = null;
			d.templateStringScript = s;
			if (s != null && GmlAPI.gmlKind[s] == null) {
				templateStringInput.classList.add("error");
				templateStringInput.title = "Couldn't find script `" + s + "`.";
			} else {
				templateStringInput.classList.remove("error");
				templateStringInput.title = "";
			}
			GmlAPI.forceTemplateStrings = s != null;
			save(project, d);
		});
		Preferences.addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-template-strings");
		templateStringInput = el.querySelectorAuto("input");
		if (d.templateStringScript != null && GmlAPI.gmlKind[d.templateStringScript] == null) {
			templateStringInput.classList.add("error");
		}
	}
	
	public static function build(project:Project, out:DivElement) {
		buildCode(project, out);
		buildSyntax(project, out);
		ui.preferences.PrefLinter.build(out, project);
		//
		plugins.PluginEvents.projectPropertiesBuilt({
			project: project,
			target: out,
		});
	}
	public static function open() {
		var kind = KProjectProperties.inst;
		var pj = Project.current;
		for (tab in ChromeTabs.getTabs()) {
			if (tab.gmlFile.kind != kind) continue;
			if ((cast tab.gmlFile.editor:KProjectPropertiesEditor).project != pj) continue;
			tab.click();
			return;
		}
		kind.create("Project properties", null, pj, null);
	}
}
