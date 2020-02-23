package ui.project;
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
	public static function build(project:Project, out:DivElement) {
		var fs:FieldSetElement;
		var d = project.properties;
		var el:Element, input:InputElement;
		inline function autosave():Void {
			save(project, d);
		}
		inline function findInput(e:Element):InputElement {
			return e.querySelectorAuto("input", InputElement);
		}
		//{
		fs = Preferences.addGroup(out, "Code editor (these take effect for newly opened editors)");
		el = Preferences.addInput(fs, "Indentation size override",
			(d.indentSize != null ? "" + d.indentSize : ""),
		function(s) {
			d.indentSize = Std.parseInt(s);
			autosave();
		});
		el.title = "Blank for default";
		//
		var indentModes = ["default", "tabs", "spaces"];
		Preferences.addRadios(fs, "Indentation mode override", indentModes[
			d.indentWithTabs == null ? 0 : (d.indentWithTabs ? 1 : 2)
		], indentModes, function(v) {
			d.indentWithTabs = v == indentModes[0] ? null : v == indentModes[1];
			autosave();
		});
		//}
		//{
		fs = Preferences.addGroup(out, "Syntax extensions");
		var lambdaModes = [
			"Default (extension)",
			"Compatible (extension macros)",
			"Scripts (GMS2 only)",
		];
		el = Preferences.addRadios(fs, "#lambda mode",
			lambdaModes[or(d.lambdaMode, Default)], lambdaModes,
		function(s) {
			d.lambdaMode = lambdaModes.indexOf(s);
			autosave();
		});
		if (project.version.config.projectModeId != 2) {
			el.querySelectorAuto("label:last-of-type input", InputElement).disabled = true;
		}
		//
		el = Preferences.addInput(fs,
			"Regex for trimming argument name (e.g. `^_(\\w+)$`)",
			or(d.argNameRegex, ""),
		function(s) {
			if (NativeString.trimBoth(s) == "") s = null;
			if (s != null) try {
				new RegExp(s);
			} catch (x:Dynamic) {
				electron.Dialog.showError("Invalid regexp: " + x);
				return;
			}
			d.argNameRegex = s;
			autosave();
		});
		//}
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
