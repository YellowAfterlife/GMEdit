package shaders;
import ace.AceMacro.jsOr;
import ace.AceMacro.rxRule;
import ace.AceWrap;
import ace.AceGmlHighlight;

/**
 * ...
 * @author YellowAfterlife
 */
@:expose("AceShaderHighlight")
@:keep class ShaderHighlight {
	@:native("$rules") public var rules:Dynamic;
	public static var nextKind:ShaderKind = ShaderKind.GLSL;
	public function new() {
		var kind:ShaderKind = nextKind;
		//
		function rule(tk:Dynamic, rx:String, ?next:String):AceLangRule {
			return { token: tk, regex: rx, next: next };
		}
		//
		var identFunc:Dynamic = switch (kind) {
			case ShaderKind.GLSL: function(s) return jsOr(ShaderAPI.glslKind[s], "identifier");
			case ShaderKind.HLSL: function(s) return jsOr(ShaderAPI.hlslKind[s], "identifier");
			default: function(_) return "identifier";
		};
		//
		rules = {
			"start": [
				rxRule("comment", ~/\/\/######################_==_YOYO_SHADER_MARKER_==_######################@~/),
				rxRule("comment.line", ~/\/\/.*/),
				rxRule("comment", ~/\/\*/, "comment"),
				rxRule("constant.numeric",
					~/0[xX][0-9a-fA-F]+(L|l|UL|ul|u|U|F|f|ll|LL|ull|ULL)?\b/
				),
				rxRule("constant.numeric",
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
			],
			"comment": [
				rxRule("comment", ~/.*?\*\//, "start"),
				cast { defaultToken: "comment" }
			],
		};
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
