package ace;
import ace.AceWrap;
import gml.GmlAPI;
import gml.GmlEnum;
import gml.GmlVersion;
import js.RegExp;
import tools.Dictionary;
import ace.AceMacro.rxRule;
import haxe.extern.EitherType;

/**
 * Syntax highlighting rules for GML
 * @author YellowAfterlife
 */
@:keep class AceGmlHighlight {
	@:native("$rules") public var rules:Dynamic;
	public var updateRules:Void->Void;
	public static var current:AceGmlHighlight = null;
	public static function update() {
		if (current != null) current.updateRules();
	}
	public function new() {
		var version = GmlAPI.version;
		current = this;
		//
		function rule(tk:Dynamic, rx:String, ?next:String):AceLangRule {
			return { token: tk, regex: rx, next: next };
		}
		function rdef(tk:String):Dynamic {
			return { defaultToken: tk };
		}
		function rpush(tk:String, rx:String, push:EitherType<String, Array<AceLangRule>>):AceLangRule {
			return { token: tk, regex: rx, push: push };
		}
		//
		function identFunc(name:String):String {
			return untyped __js__("{0} || {1} || {2} || {3}",
				GmlAPI.stdKind[name], GmlAPI.extKind[name], GmlAPI.gmlKind[name], "identifier"
			);
		}
		function identFunc2(s1:String, _, _, _, s2:String):Array<String> {
			var e = GmlAPI.gmlEnums[s1];
			if (e != null) {
				s1 = "enum";
				s2 = e.items[s2] ? "enumfield" : "enumerror";
			} else {
				s1 = identFunc(s1);
				s2 = identFunc(s2);
			}
			return [s1, "text", "punctuation.operator", "text", s2];
		}
		//
		var rTpl:AceLangRule = {
			regex: "[{}]",
			onMatch: untyped __js__('(function(val, state, stack) {
				this.next = val == "{" ? this.nextState : "";
				if (val == "{" && stack.length) {
					stack.unshift("start", state);
				}
				else if (val == "}" && stack.length) {
					stack.shift();
					this.next = stack.shift();
					if (this.next.indexOf("string") >= 0) return "quasi.paren.rparen";
				}
				switch (val) {
					case "[": return "paren.lparen";
					case "]": return "paren.rparen";
					case "{": return "curly.paren.lparen";
					case "}": return "curly.paren.rparen";
					default: return "paren";
				}
			})'),
			nextState: "start"
		};
		//
		var rBase:Array<AceLangRule> = [
			rxRule(["comment", "comment.preproc.region", "comment.regionname"],
				~/(\/\/)(#(?:end)?region[ \t]*)(.*)$/),
			rxRule("comment.doc", ~/\/\/\/.*$/),
			rxRule("comment", ~/\/\/.*$/),
			rxRule("comment.doc", ~/\/\*\*/, "comment.doc"),
			rxRule("comment", ~/\/\*/, "comment"),
			rxRule(["preproc.define", "scriptname"], ~/^(#define[ \t]+)(\w+)/),
			rxRule(["preproc.event", "eventname"], ~/^(#event[ \t]+)(\w+)/),
			rxRule(["preproc.macro", "macroname"], ~/(#macro[ \t]+)(\w+)/),
		];
		if (version == GmlVersion.live) rBase.unshift(rTpl);
		// regions:
		if (version == GmlVersion.v2) {
			rBase.push(rxRule(["preproc.region", "regionname"], ~/(#region[ \t]*)(.*)/));
			rBase.push(rxRule(["preproc.region", "regionname"], ~/(#endregion[ \t]*)(.*)/));
		} else {
			rBase.push(rxRule(["preproc.section", "sectionname"], ~/^(#section[ \t]*)(.*)/));
		}
		// strings:
		if (version == GmlVersion.v2) {
			rBase.push(rxRule("string", ~/"(?=.)/, "string.esc"));
		} else {
			rBase.push(rxRule("string", ~/"/, "string.dq"));
			rBase.push(rxRule("string", ~/'/, "string.sq"));
		}
		if (version == GmlVersion.live) {
			rBase.push({
				token: "string",
				regex: "`",
				push: [
					rpush("quasi.paren.lparen", "\\${", "start"),
					rule("string.quasi", "`", "pop"),
					rdef("string.quasi")
				]
			});
			//rBase.push(rxRule("string", ~/`/, "string.tpl"));
		}
		// normal things:
		rBase = rBase.concat([
			rxRule("constant.numeric", ~/(?:\$|0x)[0-9a-fA-F]+\b/), // $c0ffee
			rxRule("constant.numeric", ~/[+-]?\d+(?:\.\d*)?\b/), // 42.5 (GML has no E# suffixes)
			rxRule("constant.boolean", ~/(?:true|false)\b/),
			rxRule(["keyword", "text", "enum"], ~/(enum)(\s+)(\w+)/, "enum"),
			rxRule(identFunc2, ~/([a-zA-Z_][a-zA-Z0-9_]*)(\s*)(\.)(\s*)([a-zA-Z_][a-zA-Z0-9_]*)/),
			rxRule(identFunc, ~/[a-zA-Z_][a-zA-Z0-9_]*\b/),
			rxRule("set.operator", ~/=|\+=|\-=|\*=|\/=|%=|&=|\|=|\^=|<<=|>>=/),
			rxRule("operator", ~/!|%|&|\*|\-\-|\-|\+\+|\+|~|==|!=|<=|>=|<>|<|>|!|&&|\|\|/),
			rxRule("punctuation.operator", ~/\?|:|,|;|\./),
			rxRule("curly.paren.lparen", ~/\{/),
			rxRule("curly.paren.rparen", ~/\}/),
			rxRule("paren.lparen", ~/[\[(]/),
			rxRule("paren.rparen", ~/[\])]/),
			rxRule("text", ~/\s+/),
		]);
		//
		var rEnum = [
			rxRule(["enumfield", "text", "set.operator"], ~/(\w+)(\s*)(=)/, "enumvalue"),
			rxRule(["enumfield", "text", "punctuation.operator"], ~/(\w+)(\s*)(,)/),
			// todo: see if there's a better method of detecting the last item:
			rxRule(["enumfield", "text", "curly.paren.rparen"], ~/(\w+)(\s*)(\})/, "start"),
			rxRule("curly.paren.rparen", ~/\}/, "start"),
		].concat(rBase);
		//
		var rEnumValue = [
			rxRule("punctuation.operator", ~/,/, "enum"),
		].concat(rBase);
		//
		var rTemplateExpr = [
			rxRule("string", ~/\}/, "pop"),
		].concat(rBase);
		//
		if (rules != null) {
			Reflect.setField(rules, "start", rBase);
			Reflect.setField(rules, "enum", rEnum);
			Reflect.setField(rules, "enumvalue", rEnumValue);
			Reflect.setField(rules, "tplexpr", rTemplateExpr);
		} else rules = {
			"start": rBase,
			"enum": rEnum,
			"enumvalue": rEnumValue,
			"tplexpr": rTemplateExpr,
			"string.sq": [ // GMS1 single-quoted strings
				rxRule("string", ~/.*?[']/, "start"),
				rxRule("string", ~/.+/),
			],
			"string.dq": [ // GMS1 double-quoted strings
				rxRule("string", ~/.*?["]/, "start"),
				rxRule("string", ~/.+/),
			],
			"string.tpl": [ // GMLive strings with templates
				rxRule("string", ~/.*?\$\{/, "start"),
				rxRule("string", ~/.*?[`]/, "pop"),
				rxRule("string", ~/.+/),
			],
			"string.esc": [ // GMS2 strings with escape characters
				rule("string.escape", "\\\\(?:"
					+ "x[0-9a-fA-F]{2}|" // \x41
					+ "u[0-9a-fA-F]{4}|" // \u1234
					// there's also octal that doesn't work (?)
				+ ".)"),
				// (this is to allow escaping linebreaks, which is honestly a strange thing)
				cast { token : "string", regex : "\\\\$", consumeLineEnd : true },
				rule("string", '"|$', "start"),
				rdef("string"),
			],
			"comment" : [
				rxRule("comment", ~/.*?\*\//, "pop"),
				rxRule("comment", ~/.+/)
			],
			"comment.doc" : [
				rxRule("comment.doc", ~/.*?\*\//, "pop"),
				rxRule("comment.doc", ~/.+/)
			],
		};
		untyped this.normalizeRules();
	}
	//
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
	?token: EitherType<String, String->String>,
	regex: EitherType<String, RegExp>,
	?onMatch:String->String->Array<String>->String,
	?next: String,
	?nextState: String,
	?push:EitherType<String, Array<AceLangRule>>,
};
