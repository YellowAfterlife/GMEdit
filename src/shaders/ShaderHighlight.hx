package shaders;
import ace.AceMacro.jsOr;
import ace.AceMacro.rxRule;
import ace.AceMacro.rxPush;
import tools.HighlightTools.*;
import ace.AceWrap;
import ace.extern.*;
import ace.AceGmlHighlight;

/**
 * ...
 * @author YellowAfterlife
 */
@:expose("AceShaderHighlight")
@:keep class ShaderHighlight extends AceHighlight {
	public static var nextKind:ShaderKind = ShaderKind.GLSL;
	public static function makeRules(hl:AceHighlight, kind:ShaderKind):AceHighlightRuleset {
		var rules:AceHighlightRuleset = {};
		var pkg:String, identFunc:String->String;
		switch (kind) {
			case GLSL: {
				identFunc = (s) -> jsOr(ShaderAPI.glslKind[s], "identifier");
				pkg = "glsl";
			};
			case HLSL: {
				identFunc = (s) -> jsOr(ShaderAPI.hlslKind[s], "identifier");
				pkg = "hlsl";
			};
			default: {
				identFunc = (s) -> "identifier";
				pkg = "shader";
			}
		}
		rules["start"] = [
			rxRule("comment.line", ~/\/\/.*$/),
			rxPush("comment", ~/\/\*/, pkg + ".comment"),
			rxRule("numeric",
				~/0[xX][0-9a-fA-F]+(L|l|UL|ul|u|U|F|f|ll|LL|ull|ULL)?\b/
			),
			rxRule("numeric",
				~/[+-]?\d+(?:(?:\.\d*)?(?:[eE][+-]?\d+)?)?(L|l|UL|ul|u|U|F|f|ll|LL|ull|ULL)?\b/
			),
			rxRule(identFunc, ~/\w+/),
			rxRule("preproc", ~/#(\w+.+)/),
			rxRule("set.operator", ~/=|\+=|\-=|\*=|\/=|%=|&=|\|=|\^=|<<=|>>=/),
			rxRule("operator", ~/!|%|&|\*|\-\-|\-|\+\+|\+|~|==|!=|<=|>=|<>|<|>|!|&&|\|\|/),
			rxRule("punctuation.operator", ~/\?|:|,|;|\./),
			rxRule("curly.paren.lparen", ~/\{/),
			rxRule("curly.paren.rparen", ~/\}/),
			rxRule("paren.lparen", ~/[\[(]/),
			rxRule("paren.rparen", ~/[\])]/),
			rxRule("text", ~/\s+/),
		];
		rules[pkg + ".comment"] = [
			rxRule("comment", ~/.*?\*\//, "pop"),
			rdef("comment")
		];
		return rules;
	}
	public function new() {
		super();
		rules = makeRules(this, nextKind);
		normalizeRules();
	}
	public static function define(require:AceRequire, exports:AceExports, module:AceModule) {
		var oop = require("../lib/oop");
		var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;
		//
		oop.inherits(ShaderHighlight, TextHighlightRules);
		exports.ShaderHighlightRules = ShaderHighlight;
	}
	public static function init() {
		AceWrap.define("ace/mode/shader_highlight_rules", [
			"require", "exports", "module",
			"ace/lib/oop", "ace/mode/doc_comment_highlight_rules", "ace/mode/text_highlight_rules"
		], define);
	}
}
