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
import tools.Aliases.GmlName;
import tools.Dictionary;
import tools.NativeObject;
import tools.JsTools.or;
import tools.JsTools.orx;
import electron.FileWrap;
import tools.NativeString;
import ui.Preferences;
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
		fs.id = "project-properties-code";
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
	
	static function buildSearch(project:Project, out:Element) {
		var fs = Preferences.addGroup(out, "Search and indexing");
		fs.id = "project-properties-search";
		
		var d = project.properties;
		var el:Element;
		
		el = Preferences.addTextArea(fs, "Library resource names",
			(d.libraryResources ?? []).join("\n"),
		function(text:String) {
			text = NativeString.trimBoth(text);
			var lines = text.split("\n");
			d.libraryResources = lines;
			save(project, d);
			project.updateLibraryResourceMap(lines);
		});
		
		el.querySelectorAuto("label", Element).title = [
			"Library resources are omitted from search results and Global Lookup.",
			"Takes effect upon reloading the project."
		].join("\n");
	}
	
	static function addGmlNameInput(out:Element, legend:String, curr:GmlName, fn:GmlName->Void) {
		var input:InputElement = null;
		var rx = new RegExp("^[a-zA-Z_]\\w*$");
		var el = Preferences.addInput(out, legend, or(curr, ""), function(s) {
			s = NativeString.trimBoth(s);
			if (s == "") {
				s = null;
			} else if (!rx.test(s)) {
				input.classList.add("error");
				input.title = "Incorrect name format - expected a globalvar/macro/script name";
				return;
			}
			fn(s);
			if (s != null && GmlAPI.gmlKind[s] == null) {
				input.classList.add("error");
				input.title = "Couldn't find script `" + s + "`.";
			} else {
				input.classList.remove("error");
				input.title = "";
			}
		});
		input = el.querySelectorAuto("input");
		if (curr != null && GmlAPI.gmlKind[curr] == null) {
			input.classList.add("error");
		}
		return el;
	}
	
	static function buildSyntax(project:Project, out:DivElement) {
		var d = project.properties;
		inline function autoSave() {
			save(project, d);
		}
		
		var fs = Preferences.addGroup(out, "Syntax extensions");
		fs.id = "project-properties-syntax";
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
		Preferences.addCheckbox(fs, "Automatic arrow functions", d.autoArrowFunctions, (z) -> {
			d.autoArrowFunctions = z;
			autoSave();
		}).setTitleLines([
			"Auto-collapses function literals into arrow functions without /*=>*/"
		]);
		
		//
		var argRegexInput:InputElement = null;
		el = Preferences.addRegexPatternInput(fs,
			"Regex for trimming argument name (e.g. `^_(\\w+)$`)",
			d.argNameRegex,
		function(s) {
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
		el = Preferences.addRegexPatternInput(fs,
			"Regex for determining that instance/struct variables are private (e.g. `^_` for anything starting with an underscore)",
			d.privateFieldRegex,
		function(s) {
			d.privateFieldRegex = s;
			save(project, d);
		});
		
		el = Preferences.addRegexPatternInput(fs,
			"Regex for determining that global variables are private (e.g. `^_` for anything starting with an underscore)",
			d.privateGlobalRegex,
		function(s) {
			d.privateGlobalRegex = s;
			save(project, d);
		});
		
		//
		el = addGmlNameInput(fs, "Template string script name", d.templateStringScript, function(s) {
			d.templateStringScript = s;
			GmlAPI.forceTemplateStrings = s != null;
			save(project, d);
		});
		Preferences.addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-template-strings");
		
		//
		var ncGroup = Preferences.addGroup(fs, "Null-conditional operators");
		Preferences.addWiki(ncGroup, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-null-conditional-operators");
		addGmlNameInput(ncGroup, "Setter script/function name", d.nullConditionalSet, function(s) {
			d.nullConditionalSet = s;
			save(project, d);
		});
		addGmlNameInput(ncGroup, "Value globalvar/macro name", d.nullConditionalVal, function(s) {
			d.nullConditionalVal = s;
			save(project, d);
		});
	}
	
	public static function build(project:Project, out:DivElement) {
		buildCode(project, out);
		buildSearch(project, out);
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
			return tab.gmlFile;
		}
		return kind.create("Project properties", null, pj, null);
	}
}
