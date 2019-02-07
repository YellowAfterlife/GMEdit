package ace;
import ace.AceWrap;
import ace.extern.*;
import editors.EditCode;
import gml.GmlAPI;
import gml.GmlImports;
import gml.*;
import gml.file.GmlFileKind;
import haxe.DynamicAccess;
import js.RegExp;
import tools.Dictionary;
import ace.AceMacro.rxRule;
import ace.AceMacro.rxPush;
import ace.AceMacro.jsOr;
import ace.AceMacro.jsOrx;
import ace.AceMacro.jsThis;
import ace.raw.*;
import haxe.extern.EitherType;
import tools.HighlightTools.*;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
@:expose("AceMdHighlight")
@:keep class AceMdHighlight {
	@:native("$rules") public var rules:AceHighlightRuleset;
	public function new() {
		var editor:EditCode = EditCode.currentNew;
		var dmd:Bool = editor.file.kind == GmlFileKind.DocMarkdown;
		//
		var rEsc = rxRule("md-backslash", ~/\\/);
		var rBase:Array<AceLangRule> = [];
		//
		if (dmd) {
			rBase.push(rxPush("md-section", ~/#\[/, "md.section"));
			rBase.push(rxPush("md-italic", ~/\b_\B/, "md.italic"));
			rBase.push(rxPush("md-bold", ~/\B\*\b/, "md.bold"));
		} else {
			rBase.push(rxPush("md-italic", ~/\b(?:__|\*\*)\B/, "md.italic"));
			rBase.push(rxPush("md-bold", ~/\b(?:_|\*)\B/, "md.bold"));
		}
		//
		rBase.push(rxPush("md-pre-start", ~/```(?:\B|gml\b)/, "md.gml"));
		rBase.push(rxPush("md-pre-start", ~/```(?:haxe\b|exec\b)/, "md.haxe"));
		rBase.push(rxPush("md-pre-start", ~/```\w+\b/, "md.pre"));
		rBase.push(rxPush("md-tt", ~/`/, "md.tt"));
		//
		function rcct(r:Array<AceLangRule>, d:AceLangRule):Array<AceLangRule> {
			r = r.concat(rBase);
			r.push(d);
			r.unshift(rEsc);
			return r;
		}
		rules = {};
		rules["start"] = rcct([], rdef("text"));
		if (dmd) {
			rules["md.section"] = [
				rxPush("md-section", ~/\[/, "md.section"),
				rxRule(["md-section", "md-href-start"], ~/(\])(\()/, "md.href"),
				rxRule("md-section", ~/\]/, "pop"),
				rdef("md-section"),
			];
			rules["md.href"] = [rEsc,
				rxRule("md-href-end", ~/\)/, "pop"),
				rdef("md-href"),
			];
			rules["md.italic"] = rcct([
				rxRule("md-italic", ~/\B_\b/, "pop")
			], rdef("md-italic"));
			rules["md.bold"] = rcct([rEsc,
				rxRule("md-bold", ~/\b\*\B/, "pop")
			], rdef("md-bold"));
		} else {
			rules["md.italic"] = rcct([
				rxRule("md-italic", ~/?:__|\*\*)\b/, "pop")
			], rdef("md-italic"));
			rules["md.bold"] = rcct([rEsc,
				rxRule("md-bold", ~/(?:_|\*)\b/, "pop")
			], rdef("md-bold"));
		}
		rules["md.tt"] = [rEsc, rxRule("md-tt", ~/`/, "pop"), rdef("md-tt")];
		//
		rules["md.haxe"] = [rEsc, rxRule("md-pre-end", ~/```/, "pop"), rdef("md-pre")];
		//
		var gmlRules:AceHighlightRuleset = AceGmlHighlight.makeRules(editor);
		var gmlRulesStart = gmlRules["start"];
		gmlRules.remove("start");
		gmlRulesStart.unshift(rxRule("md-pre-end", ~/```/, "pop"));
		gmlRulesStart.pop(); // remove the default rule
		gmlRulesStart.push(rdef("md-pre-gml"));
		for (key in gmlRules.keys()) rules[key] = gmlRules[key];
		rules["md.gml"] = gmlRulesStart;
		//
		rules["md.pre"] = [rEsc, rxRule("md-pre-end", ~/```/, "pop"), rdef("md-pre")];
		untyped this.normalizeRules();
	}
	public static function define(require:AceRequire, exports:AceExports, module:AceModule) {
		var oop = require("../lib/oop");
		var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;
		//
		oop.inherits(AceMdHighlight, TextHighlightRules);
		exports.MarkdownHighlightRules = AceMdHighlight;
	}
	public static function init() {
		AceWrap.define("ace/mode/markdown_highlight_rules", [
			"require", "exports", "module",
			"ace/lib/oop", "ace/mode/doc_comment_highlight_rules", "ace/mode/text_highlight_rules"
		], define);
	}
}
