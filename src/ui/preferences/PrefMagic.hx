package ui.preferences;
import js.html.Element;
import ui.Preferences.*;
import ui.ext.GMLive;
import ui.treeview.TreeView;
import ui.preferences.PrefData;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class PrefMagic {
	public static function build(out:Element) {
		out = addGroup(out, "Syntax extensions");
		out.id = "pref-magic";
		var el:Element, gr:Element;
		
		//
		gr = addGroup(out, "#args magic"); {
			addWiki(gr, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-%23args-magic");
			//
			el = addCheckbox(gr, "Use `#args` magic", current.argsMagic, function(z) {
				current.argsMagic = z;
				save();
			});
			el.title = "Allows writing `#args a, b` instead of `var a = argument0, b = argument1`.";
			//
			var noAutoArgs = "Don't auto-generate";
			el = addDropdown(gr, "JSDoc format for #args",
				current.argsFormat != "" ? current.argsFormat : noAutoArgs,
				[noAutoArgs, "@arg", "@param", "@argument"],
			function(v) {
				if (v == noAutoArgs) v = "";
				current.argsFormat = v;
				save();
			});
			//
			el = addCheckbox(gr, "Strict mode", current.argsStrict, function(z) {
				current.argsStrict = z;
				save();
			});
			el.title = "Doesn't collapse arguments unless the format is binary identical.";
		};
		
		//
		el = addCheckbox(out, "Use `#import` magic", current.importMagic, function(z) {
			current.importMagic = z;
			save();
		});
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-%23import-magic");
		el.title = "Allows setting up rules for shortening names per-script.";
		
		//
		addCheckbox(out, "Allow undo-ing `#import`", current.allowImportUndo, function(z) {
			current.allowImportUndo = z;
			save();
		}).title = "Allows undoing name changes made after changing #import rules."
			+ "\nMakes it easier to break code, so be careful.";
		
		//
		el = addCheckbox(out, "Use `#mfunc` magic", current.mfuncMagic, function(z) {
			current.mfuncMagic = z;
			save();
		});
		el.title = "Allows C-style macros with arguments";
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-%23mfunc-magic");
		
		//
		el = addCheckbox(out, "Use coroutine magic", current.coroutineMagic, function(z) {
			current.coroutineMagic = z;
			if (z) synext.GmlExtCoroutines.ensureScript();
			save();
		});
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-%23gmcr-magic");
		
		//
		el = addCheckbox(out, "Use lambda magic", current.lambdaMagic, function(z) {
			current.lambdaMagic = z;
			save();
		});
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-%23lambda-magic");
		
		/*// Soon (tm)
		el = addCheckbox(out, "Use GMHyper magic", current.hyperMagic, function(z) {
			current.hyperMagic = z;
			save();
		});
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/GMHyper-in-GMEdit");*/
		
		//
		el = addCheckbox(out, "Use ??= operator", current.nullCoalescingAssignment, function(z) {
			current.nullCoalescingAssignment = z;
			save();
		});
		el.title = "Allows to write `a ??= b` instead of `if (a == undefined) a = b`";
		addWiki(el, "https://github.com/YellowAfterlife/GMEdit/wiki/Using-null-conditional-assignment");
		
		//
		el = addCheckbox(out, "Use cast/as linter 'operators'", current.castOperators, function(z) {
			current.castOperators = z;
			save();
		});
		el.title = "Used for implicit/explicit casts";
		addWiki(el, "https://github.com/YellowAfterlife/GMEdit/wiki/Smart-completion#x-as-y");
		
		//
		el = addCheckbox(out, "Use `#RrGgBb` color literals", current.hashColorLiterals, function(z) {
			current.hashColorLiterals = z;
			save();
		});
		el.title = "(as an alternative to usual 0xBbGgRr)";
		
		el = addCheckbox(out, "Use arrow function shorthands", current.arrowFunctions, function(z) {
			current.arrowFunctions = z;
			save();
		});
		el.title = "Lets you write (a, b) => c instead of function(a, b) { return c } and alike";
		addWiki(el, "https://github.com/YellowAfterlife/GMEdit/wiki/Using-arrow-functions");
		
		//
		#if !gmedit.live
		var optGMLive = ["Hide", "Show on items", "Show everywhere"];
		el = addDropdown(out, "Show GMLive badges", optGMLive[current.showGMLive], optGMLive, function(v) {
			var v0:PrefGMLive = current.showGMLive;
			var v1:PrefGMLive = optGMLive.indexOf(v);
			if (v0 == v1) return;
			current.showGMLive = v1;
			if (gml.Project.current.hasGMLive) {
				if (v0.isActive() != v1.isActive()) {
					for (el in TreeView.element.querySelectorEls(".item")) {
						if (v1.isActive()) {
							var data = parsers.GmlSeekData.map[el.getAttribute(TreeView.attrPath)];
							if (data != null) {
								if (data.hasGMLive) {
									el.setAttribute(GMLive.attr, "");
								} else el.removeAttribute(GMLive.attr);
							}
						} else el.removeAttribute(GMLive.attr);
					}
				}
				GMLive.updateAll(true);
			}
			save();
		});
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/GMLive-in-GMEdit");
		#end
	}
}
