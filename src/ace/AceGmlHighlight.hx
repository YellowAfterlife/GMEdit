package ace;
import ace.AceWrap;
import js.RegExp;
import tools.Dictionary;
import ace.AceMacro.rule;
import haxe.extern.EitherType;

/**
 * Syntax highlighting rules for GML
 * @author YellowAfterlife
 */
@:keep class AceGmlHighlight {
	@:native("$rules") public var rules:Dynamic;
	public function new() {
		//
		function rule1(tk:Dynamic, rx:String, next:String):AceLangRule {
			return { token: tk, regex: rx, next: next };
		}
		function rdef(tk:String):Dynamic {
			return { defaultToken: tk };
		}
		//
		function identFunc(name:String):String {
			return untyped __js__("{0} || {1} || {2} || {3}",
				GmlAPI.stdKind[name], GmlAPI.extKind[name], GmlAPI.gmlKind[name], "identifier"
			);
		}
		var baseRules:Array<AceLangRule> = [
			rule("comment.doc", ~/\/\/\/.*$/),
			rule("comment", ~/\/\/.*$/),
			rule("comment.doc", ~/\/\*\*/, "comment.doc"),
			rule("comment", ~/\/\*/, "comment"),
			rule(["preproc.define", "script"], ~/(#define[ \t]+)(\w+)/),
			rule(["preproc.macro", "variable"], ~/(#macro[ \t]+)(\w+)/),
			rule("string", ~/"/, "string2"),
			rule("string", ~/'/, "string1"),
			rule("string", ~/`/, "stringt"),
			rule("constant.numeric", ~/(?:\$|0x)[0-9a-fA-F]+\b/), // $c0ffee
			rule("constant.numeric", ~/[+-]?\d+(?:\.\d*)?\b/), // 42.5 (GML has no E# suffixes)
			rule("constant.boolean", ~/(?:true|false)\b/),
			rule(identFunc, ~/[a-zA-Z_][a-zA-Z0-9_]*\b/),
			rule("set.operator", ~/=|\+=|\-=|\*=|\/=|%=|&=|\|=|\^=|<<=|>>=/),
			rule("operator", ~/!|%|&|\*|\-\-|\-|\+\+|\+|~|==|!=|<=|>=|<>|<|>|!|&&|\|\|/),
			rule("punctuation.operator", ~/\?|:|,|;|\./),
			rule("curly.paren.lparen", ~/\{/),
			rule("curly.paren.rparen", ~/\}/),
			rule("paren.lparen", ~/[\[(]/),
			rule("paren.rparen", ~/[\])]/),
			rule("text", ~/\s+/),
		];
		rules = {
			"start": baseRules,
			"string1" : [
				rule("string", ~/.*?[']/, "start"),
				rule("string", ~/.+/),
			],
			"string2" : [
				rule("string", ~/.*?["]/, "start"),
				rule("string", ~/.+/),
			],
			"stringt" : [
				rule("string", ~/.*?[`]/, "start"),
				rdef("string"),
			],
			"comment" : [
				rule("comment", ~/.*?\*\//, "start"),
				rule("comment", ~/.+/)
			],
			"comment.doc" : [
				rule("comment.doc", ~/.*?\*\//, "start"),
				rule("comment.doc", ~/.+/)
			],
		};
	}
	public static function define(require:AceRequire, exports:AceExports, module:AceModule) {
		var oop = require("../lib/oop");
		var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;
		//
		oop.inherits(AceGmlHighlight, TextHighlightRules);
		exports.GmlHighlightRules = AceGmlHighlight;
	}
	public static function init() {
		AceWrap.define("ace/mode/gml_highlight_rules", [
			"require", "exports", "module",
			"ace/lib/oop", "ace/mode/doc_comment_highlight_rules", "ace/mode/text_highlight_rules"
		], define);
	}
}
typedef AceLangRule = {
	token: EitherType<String, String->String>,
	regex: EitherType<String, RegExp>,
	next: String,
};
