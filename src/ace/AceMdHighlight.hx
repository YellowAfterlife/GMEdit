package ace;
import ace.AceWrap;
import ace.extern.*;
import editors.EditCode;
import file.kind.misc.KMarkdown;
import gml.GmlAPI;
import gml.GmlImports;
import gml.*;
import haxe.DynamicAccess;
import js.lib.RegExp;
import shaders.ShaderHighlight;
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
@:keep class AceMdHighlight extends AceHighlight{
	public function new() {
		super();
		var editor:EditCode = EditCode.currentNew;
		var dmd:Bool = Std.is(editor.kind, KMarkdown) && (cast editor.kind:KMarkdown).isDocMd;
		//
		var rEsc = rxRule("md-escape", ~/\\(?:.|$)/);
		var rBase:Array<AceLangRule> = [];
		var rText = rxRule("text", ~/\s+/);
		//
		if (dmd) {
			rBase.push(rxPush("md-section-start", ~/#+\[/, "md.section"));
			rBase.push(rxPush("md-italic", ~/\b_\B/, "md.italic"));
			rBase.push(rxPush("md-bold", ~/\*/, "md.bold"));
		} else {
			rBase.push(rxPush("md-italic", ~/\b(?:__|\*\*)\B/, "md.italic"));
			rBase.push(rxPush("md-bold", ~/\b(?:_|\*)\B/, "md.bold"));
		}
		rBase.push(rulePairs([
			"^\\s#+\\s*", "md-section-prefix",
			".*$", "md-section",
		]));
		//
		rBase.push(rxPush("md-url-start", ~/\[/, "md.url"));
		if (dmd) {
			rBase.push(rxPush(function(_) {
				if (GmlAPI.version == GmlVersion.none) {
					GmlAPI.version = GmlVersion.v2;
					GmlAPI.init();
				}
				return "md-pre-start";
			}, ~/```(?:\B|gml\b)/, "md.gml"));
			rBase.push(rxPush([
				"md-pre-start", "md-url"
			], ~/(```\w*md\b\s*)(\w*)/, "md.md"));
			rBase.push(rxPush(["md-expr-start", "curly.paren.lparen"], ~/(\$)(\{)/, "md.expr"));
		} else rBase.push(rxPush("md-pre-start", ~/```gml\b/, "md.gml"));
		rBase.push(rxPush("md-pre-start", ~/```(?:haxe\b|exec\b)/, "md.hx"));
		rBase.push(rxPush("md-pre-start", ~/```glsl\b/, "md.glsl"));
		rBase.push(rxPush("md-pre-start", ~/```hlsl\b/, "md.hlsl"));
		rBase.push(rxPush("md-pre-start", ~/```/, "md.pre"));
		rBase.push(rxPush("md-tt", ~/`/, "md.tt"));
		rBase.push(rxPush("comment", ~/<!--/, "md.comment"));
		//
		function rcct(r:Array<AceLangRule>, d:AceLangRule):Array<AceLangRule> {
			r = r.concat(rBase);
			r.push(d);
			r.unshift(rEsc);
			return r;
		}
		rules = {};
		rules["start"] = rcct([], rText);
		if (dmd) {
			rules["md.section"] = [
				rxPush("md-section-start", ~/\[/, "md.section"),
				rxRule(["md-section-end", "md-href-start"], ~/(\])(\()/, "md.href"),
				rxRule("md-section-end", ~/(?:\]|$)/, "pop"),
				rdef("md-section"),
			];
			rules["md.italic"] = rcct([
				rxRule("md-italic", ~/(?:\B_\b|$)/, "pop"),
			], rdef("md-italic"));
			rules["md.bold"] = rcct([rEsc,
				rxRule("md-bold", ~/(?:\*|$)/, "pop"),
			], rdef("md-bold"));
		} else {
			rules["md.italic"] = rcct([
				rxRule("md-italic", ~/(?:__|\*\*)\b/, "pop")
			], rdef("md-italic"));
			rules["md.bold"] = rcct([rEsc,
				rxRule("md-bold", ~/(?:_|\*)\b/, "pop")
			], rdef("md-bold"));
		}
		//
		rules["md.comment"] = [
			rxRule("comment", ~/-->/, "pop"),
			rdef("comment"),
		];
		rules["md.url"] = [rEsc,
			rxRule(["md-url-end", "md-href-start"], ~/(\])(\()/, "md.href"),
			rxRule("md-url-end", ~/(?:\]|$)/, "pop"),
			rdef("md-url"),
		];
		rules["md.href"] = [rEsc,
			rxRule("md-href-end", ~/(?:\)|$)/, "pop"),
			rdef("md-href"),
		];
		rules["md.tt"] = [rEsc, rxRule("md-tt", ~/(?:`|$)/, "pop"), rdef("md-tt")];
		//
		function addBlock(substart:String, def:String, subset:AceHighlightRuleset) {
			var start = subset["start"].slice(0);
			start.unshift(rxRule("md-pre-end", ~/```/, "pop"));
			start.pop(); // remove the default rule
			start.push(rdef(def));
			for (key in subset.keys()) if (key != "start") rules[key] = subset[key];
			rules[substart] = start;
		}
		var rHaxe = AceHxHighlight.makeRules(this);
		addBlock("md.gml", "md-pre-gml", AceGmlHighlight.makeRules(editor));
		addBlock("md.hx", "md-pre-hx", rHaxe);
		addBlock("md.glsl", "md-pre-glsl", ShaderHighlight.makeRules(this, GLSL));
		addBlock("md.hlsl", "md-pre-hlsl", ShaderHighlight.makeRules(this, HLSL));
		if (dmd) rules["md.expr"] = [ // inline Haxe expression
			rxPush("curly.paren.lparen", ~/\{/, "md.expr"),
			rxRule("curly.paren.rparen", ~/\}/, "pop"),
		].concat(rHaxe["start"]).concat([rText]);
		if (dmd) rules["md.md"] = rcct([
			rxRule("md-pre-end", ~/```/, "pop")
		], rText);
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
