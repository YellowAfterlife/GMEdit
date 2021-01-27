package ui.preferences;
import js.html.Element;
import parsers.linter.GmlLinterPrefs;
import gml.Project;
import ui.Preferences.*;
import gml.GmlAPI;
import gml.file.GmlFile;
using tools.HtmlTools;
import js.html.SelectElement;
import file.kind.misc.KSnippets;
import tools.macros.PrefLinterMacros.*;

/**
 * ...
 * @author ...
 */
class PrefLinter {
	static var selectOpts:Array<String> = ["inherit", "on", "off"];
	static var selectVals:Array<Bool> = [null, true, false];
	public static function build(out:Element, project:Project) {
		out = addGroup(out, "Linter");
		if (project != null) {
			out.id = "project-properties-linter";
		} else out.id = "pref-linter";
		var el:Element;
		//
		var opt:GmlLinterPrefs;
		if (project != null) {
			opt = project.properties.linterPrefs;
			if (opt == null) {
				opt = project.properties.linterPrefs = {};
			}
		} else opt = current.linterPrefs;
		function saveOpt() {
			if (project != null) {
				ui.project.ProjectProperties.save(project, project.properties);
			} else {
				Preferences.save();
			}
		}
		//
		function add(name:String,
			get:GmlLinterPrefs->Bool,
			set:GmlLinterPrefs->Null<Bool>->Void,
		defValue:Bool):Element {
			var initialValue = get(opt);
			if (project != null) {
				var options = PrefLinter.selectOpts.copy();
				var values = selectVals;
				var parentValue = get(current.linterPrefs);
				if (parentValue == null) parentValue = defValue;
				options[0] += ' (➜ ' + (parentValue ? "on" : "off") + ")";
				//
				if (initialValue == null) initialValue = null; // undefined -> null
				var initialOption = options[values.indexOf(initialValue)];
				return addDropdown(out, name, initialOption, options, function(s) {
					var z = values[options.indexOf(s)];
					set(opt, z);
					saveOpt();
				});
			} else {
				if (initialValue == null) initialValue = defValue;
				return addCheckbox(out, name, initialValue, function(z) {
					set(opt, z);
					saveOpt();
				});
			}
		}
		var orig = out;
		
		out = addGroup(orig, "Behaviour");
		addf("Syntax check on load", opt.onLoad);
		addf("Syntax check on save", opt.onSave);
		
		out = addGroup(orig, "Code style");
		addf("Warn about missing semicolons", opt.requireSemicolons);
		addf("Warn about single `=` comparisons", opt.noSingleEquals);
		addf("Warn about conditions without ()", opt.requireParentheses);
		
		out = addGroup(orig, "Scripts and functions");
		addf("Warn about missing functions", opt.requireFunctions);
		el = addf("Warn about trying to use result of a script/function with no returned values", opt.checkHasReturn);
		el.title = "For functions, the list of functions without return values can be found in resources/app/api/<version>/noret.gml";
		addf("Warn about mismatched argument counts on user-defined scripts/functions", opt.checkScriptArgumentCounts);
		addf("Warn about missing fields on a.b access", opt.requireFields);
		
		out = addGroup(orig, "Block scoping");
		el = addf("Treat `var` as block-scoped", opt.blockScopedVar);
		el.title = "You can also use `#macro const var` and `#macro let var`";
		el = addf("Treat `case` as block-scoped", opt.blockScopedCase);
		el.title = "Allows cases to redefine block-scoped variables inside cases, but variables in fall-through cases will not be considered accessible in subsequent case(s)";
		
		out = addGroup(orig, "Implicit types for local variables");
		addf("For `var`", opt.specTypeVar);
		addf("For `let`", opt.specTypeLet);
		addf("For `const`", opt.specTypeConst);
		addf("For other `var` macros", opt.specTypeMisc);
	}
}
