package ui.preferences;
import js.html.Element;
import js.html.InputElement;
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
		function aBool(name:String,
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
		function aInt(name:String,
			get:GmlLinterPrefs->Int,
			set:GmlLinterPrefs->Null<Int>->Void,
		defValue:Int):Element {
			var initialValue = get(opt);
			if (project != null) {
				var parentValue = get(current.linterPrefs);
				if (parentValue == null) parentValue = defValue;
				//
				var fd:InputElement = null;
				var el = addInput(out, name, initialValue != null ? ("" + initialValue) : "", function(s) {
					var i:Null<Int>;
					if (s == "") {
						fd.classList.remove("error");
						i = null;
					} else {
						i = Std.parseInt(s);
						if (i != null) {
							fd.classList.remove("error");
						} else {
							fd.classList.add("error");
							return;
						}
					}
					set(opt, i);
					saveOpt();
				});
				fd = el.querySelectorAuto("input");
				fd.placeholder = "" + parentValue;
				return el;
			} else {
				if (initialValue == null) initialValue = defValue;
				return addIntInput(out, name, initialValue, function(i) {
					set(opt, i);
					saveOpt();
				});
			}
		}
		var orig = out;
		
		out = addGroup(orig, "Behaviour");
		addf(aBool, "Syntax check on load", opt.onLoad);
		addf(aBool, "Syntax check on save", opt.onSave);
		
		out = addGroup(out, "Live update (experimental)");
		addf(aInt, "Run linter after a period of inactivity (in ms; 0 to disable)", opt.liveIdleDelay);
		addf(aInt, "Max lines per file for checks after periods of inactivity", opt.liveIdleMaxLines);
		addf(aBool, "Syntax check on pressing Enter", opt.liveCheckOnEnter);
		addf(aBool, "Syntax check on pressing `;`", opt.liveCheckOnSemico);
		addf(aInt, "Max lines per file for checks on Enter and `;`", opt.liveMaxLines);
		addf(aInt, "Minimum delay between checks (in ms)", opt.liveMinDelay);
		
		out = addGroup(orig, "Code style");
		addf(aBool, "Warn about missing semicolons", opt.requireSemicolons);
		addf(aBool, "Warn about single `=` comparisons", opt.noSingleEquals);
		addf(aBool, "Warn about conditions without ()", opt.requireParentheses);
		
		out = addGroup(orig, "Scripts and functions");
		addf(aBool, "Warn about missing functions", opt.requireFunctions);
		el = addf(aBool, "Warn about trying to use result of a script/function with no returned values", opt.checkHasReturn);
		el.title = "For functions, the list of functions without return values can be found in resources/app/api/<version>/noret.gml";
		addf(aBool, "Warn about mismatched argument counts on user-defined scripts/functions", opt.checkScriptArgumentCounts);
		
		out = addGroup(orig, "Misc.");
		addf(aBool, "Warn about missing fields on a.b access", opt.requireFields);
		addf(aBool, "Allow implicitly casting Type? to Type", opt.implicitNullableCasts);
		addf(aBool, "Allow implicitly casting between bool and int", opt.implicitBoolIntCasts);
		addf(aBool, "Warn about redundant casts (e.g. for `4 as number`)", opt.warnAboutRedundantCasts);
		addf(aBool, "Treat scripts without @self as having `void` self", opt.strictScriptSelf);
		
		out = addGroup(orig, "Block scoping");
		el = addf(aBool, "Treat `var` as block-scoped", opt.blockScopedVar);
		el.title = "You can also use `#macro const var` and `#macro let var`";
		el = addf(aBool, "Treat `case` as block-scoped", opt.blockScopedCase);
		el.title = "Allows cases to redefine block-scoped variables inside cases, but variables in fall-through cases will not be considered accessible in subsequent case(s)";
		
		out = addGroup(orig, "Implicit types");
		addf(aBool, "For `var`", opt.specTypeVar);
		addf(aBool, "For `static`", opt.specTypeStatic);
		addf(aBool, "For `let`", opt.specTypeLet);
		addf(aBool, "For `const`", opt.specTypeConst);
		addf(aBool, "For other `var` macros", opt.specTypeMisc);
		el = addf(aBool, "When using := to assign", opt.specTypeColon);
		el.title = "(idea stolen from Godot)";
		addf(aBool, "For simple instance/constructor variables (numbers, booleans, strings, `new`)", opt.specTypeInst);
		el = addf(aBool, "Allow non-top-level assignments", opt.specTypeInstSubTopLevel);
		el.title = "May mis-fire on bracket-less `with` blocks and alike";
	}
}
