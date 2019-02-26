package ace;
import ace.AceWrap;
import ace.extern.*;
import editors.EditCode;
import gml.GmlAPI;
import gml.GmlImports;
import gml.*;
import haxe.DynamicAccess;
import js.RegExp;
import tools.Dictionary;
import ace.AceMacro.rxRule;
import ace.AceMacro.rxPush;
import ace.AceMacro.jsOr;
import ace.AceMacro.jsOrx;
import ace.AceMacro.jsThis;
import haxe.extern.EitherType;
import tools.HighlightTools.*;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 * 
 */
@:expose("AceHxHighlight")
@:keep class AceHxHighlight extends AceHighlight {
	public static function makeRules(hl:AceHighlight):AceHighlightRuleset {
		var editor = hl.editor;
		var kwmapper = hl.createKeywordMapper({
			"keyword": "package|import|using"
				+ "|class|enum|abstract|typedef|interface|extends|implements" 
				+ "|inline|extern|override|private|public|static"
				+ "|function|var|new|super|this|trace"
				+ "|if|else|for|in|while|do|switch|case|default|break|continue"
				+ "|return|try|throw|catch|cast|untyped",
			"constant.boolean": "true|false",
			"constant": "null"
		}, "identifier");
		var docTags = "author|param|return|throws|see|link|since";
		var base = [
			rxRule("comment.line.doc", ~/\/\/\/.*$/),
			rxRule("comment.line", ~/\/\/.*$/),
			rxPush("comment.doc", ~/\/\*\*/, "hx.comment.doc"),
			rxPush("comment", ~/\/\*/, "hx.comment"),
			rxRule("numeric", ~/0[xX][0-9a-fA-F]+\b/),
			rxRule("numeric", ~/[+-]?\d+(?:(?:\.\d*)?(?:[eE][+-]?\d+)?)?\b/),
			rule("string.regexp", "[/](?:(?:\\[(?:\\\\]|[^\\]])+\\])|(?:\\\\/|[^\\]/]))*[/]\\w*\\s*(?=[).,;]|$)"),
			rule("string", '["](?:(?:\\\\.)|(?:[^"\\\\]))*?(?:["]|$)'),
			rxRule(kwmapper, ~/\w+/),
			rxPush("string", ~/'/, "hx.string"),
			rxRule("set.operator", ~/=|\+=|\-=|\*=|\/=|%=|&=|\|=|\^=|<<=|>>=/),
			rxRule("operator", ~/!|%|&|\*|\-\-|\-|\+\+|\+|~|==|!=|<=|>=|<|>|!|&&|\|\|/),
			rxRule("punctuation.operator", ~/\?|:|,|;|\./),
			rxRule("curly.paren.lparen", ~/\{/),
			rxRule("curly.paren.rparen", ~/\}/),
			rxRule("square.paren.lparen", ~/\[/),
			rxRule("square.paren.rparen", ~/\]/),
			rxRule("paren.lparen", ~/\(/),
			rxRule("paren.rparen", ~/\)/),
			rxRule("text", ~/\s+/),
		];
		return {
			"start": base,
			"hx.comment.doc": [
				rule("comment.meta", '@(?:$docTags)'),
				rxRule("comment.doc", ~/\*\//, "pop"),
				rdef("comment.doc")
			],
			"hx.comment": [
				rxRule("comment", ~/\*\//, "pop"),
				rdef("comment")
			],
			"hx.string": [
				rxPush(["string", "curly.paren.lparen"], ~/(\$)(\{)/, "hx.string.code"),
				rule("string.escape", "\\\\(?:"
					+ "x[0-9a-fA-F]{2}|" // \x41
					+ "u[0-9a-fA-F]{4}|" // \u1234
					// there's also octal which doesn't work (?)
				+ ".)"),
				rxRule("string", ~/(?:'|$)/, "pop"),
				rdef("string"),
			],
			"hx.string.code": [
				rxPush("curly.paren.lparen", ~/\{/, "hx.string.code"),
				rxRule("curly.paren.rparen", ~/\}/, "pop")
			].concat(base),
		};
	}
	public function new() {
		super();
		rules = makeRules(this);
		normalizeRules();
	}
	public static function define(require:AceRequire, exports:AceExports, module:AceModule) {
		var oop = require("../lib/oop");
		var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;
		//
		oop.inherits(AceHxHighlight, TextHighlightRules);
		exports.HaxeHighlightRules = AceHxHighlight;
	}
	public static function init() {
		AceWrap.define("ace/mode/haxe_highlight_rules", [
			"require", "exports", "module",
			"ace/lib/oop", "ace/mode/doc_comment_highlight_rules", "ace/mode/text_highlight_rules"
		], define);
	}
}
