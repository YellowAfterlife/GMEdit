package ace;
import ace.AceWrap;
import gml.GmlAPI;
import gml.GmlEnum;
import gml.GmlVersion;
import js.RegExp;
import tools.Dictionary;
import ace.AceMacro.rxRule;
import ace.AceMacro.jsOr;
import ace.AceMacro.jsThis;
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
		inline function getGlobalType(name:String, fallback:String) {
			return jsOr(GmlAPI.gmlKind[name],
				jsOr(GmlAPI.extKind[name],
					jsOr(GmlAPI.stdKind[name], fallback)
				)
			);
		}
		//
		inline function token(type:String, value:String):Dynamic {
			return { type: type, value: value };
		}
		inline function getLocalType(row:Int, name:String):String {
			if (row != null) {
				var scope = gml.GmlScopes.get(row);
				if (scope != null) {
					var locals = gml.GmlLocals.currentMap[scope];
					if (locals != null) {
						return locals.kind[name];
					} else return null;
				} else return null;
			} else return null;
		}
		var rIdentLocal:AceLangRule = {
			regex: '[a-zA-Z_][a-zA-Z0-9_]*\\b',
			onMatch: function(
				value:String, state:String, stack:Array<String>, line:String, row:Int
			) {
				var type:String = getLocalType(row, value);
				if (type == null) type = getGlobalType(value, "identifier");
				return [token(type, value)];
			},
		};
		var rIdentPair:AceLangRule = {
			regex: '([a-zA-Z_][a-zA-Z0-9_]*)(\\s*)(\\.)(\\s*)([a-zA-Z_][a-zA-Z0-9_]*)',
			onMatch: function(
				value:String, state:String, stack:Array<String>, line:String, row:Int
			) {
				var values:Array<String> = jsThis.splitRegex.exec(value);
				var object = values[1];
				var field = values[5];
				var objType:String, fdType:String;
				if (object == "global") {
					objType = "keyword";
					fdType = "globalvar";
				} else {
					objType = getLocalType(row, object);
					if (objType == null) {
						var en = GmlAPI.gmlEnums[object];
						if (en != null) {
							objType = "enum";
							fdType = en.items[field] ? "enumfield" : "enumerror";
						} else {
							objType = getGlobalType(object, "identifier");
							fdType = getGlobalType(field, "field");
						}
					} else fdType = getGlobalType(field, "field");
				}
				return [
					token(objType, object),
					token("text", values[2]),
					token("punctuation.operator", values[3]),
					token("text", values[4]),
					token(fdType, field),
				];
			}
		};
		function mtField(_, field:String) {
			return ["punctuation.operator", "text", getGlobalType(field, "field")];
		}
		function mtIdent(ident:String) {
			return getGlobalType(ident, "identifier");
		}
		//
		var rTpl:AceLangRule = {
			regex: "[{}]",
			onMatch: untyped __js__('(function(val, state, stack)
			{
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
			})
			'),
			nextState: "start"
		};
		var rBase:Array<AceLangRule> = [ //{ comments and preprocessors
			rxRule(["comment", "comment.preproc.region", "comment.regionname"],
				~/(\/\/)(#(?:end)?region[ \t]*)(.*)$/),
			rxRule("comment.doc.line", ~/\/\/\/$/),
			rxRule("comment.doc.line", ~/\/\/\//, "comment.doc.line"),
			rxRule("comment.line", ~/\/\/$/),
			rxRule("comment.line", ~/\/\//, "comment.line"),
			rxRule("comment.doc", ~/\/\*\*/, "comment.doc"),
			rxRule("comment", ~/\/\*/, "comment"),
			rxRule(["preproc.define", "scriptname"], ~/^(#define[ \t]+)(\w+)/),
			rxRule(["preproc.event", "eventname"], ~/^(#event[ \t]+)(\w+)/),
			rxRule(["preproc.macro", "macroname"], ~/(#macro[ \t]+)(\w+)/),
		]; //}
		if (version == GmlVersion.live) rBase.unshift(rTpl);
		if (version == GmlVersion.v2) { // regions
			rBase.push(rxRule(["preproc.region", "regionname"], ~/(#region[ \t]*)(.*)/));
			rBase.push(rxRule(["preproc.region", "regionname"], ~/(#endregion[ \t]*)(.*)/));
		} else {
			rBase.push(rxRule(["preproc.section", "sectionname"], ~/^(#section[ \t]*)(.*)/));
		}
		if (version == GmlVersion.v2) { // strings
			rBase.push(rxRule("string", ~/"(?=.)/, "string.esc"));
		} else {
			rBase.push(rxRule("string", ~/"/, "string.dq"));
			rBase.push(rxRule("string", ~/'/, "string.sq"));
		}
		if (version == GmlVersion.live) { // template strings
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
		rBase = rBase.concat([ //{
			rxRule("constant.numeric", ~/(?:\$|0x)[0-9a-fA-F]+\b/), // $c0ffee
			rxRule("constant.numeric", ~/[+-]?\d+(?:\.\d*)?\b/), // 42.5 (GML has no E# suffixes)
			rxRule("constant.boolean", ~/(?:true|false)\b/),
			rxRule(["keyword", "text", "enum"], ~/(enum)(\s+)(\w+)/, "enum"),
			rIdentPair,
			rIdentLocal,
			rxRule(mtField, ~/(\.)(\s+)([a-zA-Z_][a-zA-Z0-9_]*)/),
			rxRule(mtIdent, ~/[a-zA-Z_][a-zA-Z0-9_]*\b/),
			rxRule("set.operator", ~/=|\+=|\-=|\*=|\/=|%=|&=|\|=|\^=|<<=|>>=/),
			rxRule("operator", ~/!|%|&|\*|\-\-|\-|\+\+|\+|~|==|!=|<=|>=|<>|<|>|!|&&|\|\|/),
			rxRule("punctuation.operator", ~/\?|:|,|;|\./),
			rxRule("curly.paren.lparen", ~/\{/),
			rxRule("curly.paren.rparen", ~/\}/),
			rxRule("paren.lparen", ~/[\[(]/),
			rxRule("paren.rparen", ~/[\])]/),
			rxRule("text", ~/\s+/),
		]); //}
		var rEnum = [ //{
			rxRule(["enumfield", "text", "set.operator"], ~/(\w+)(\s*)(=)/, "enumvalue"),
			rxRule(["enumfield", "text", "punctuation.operator"], ~/(\w+)(\s*)(,)/),
			// todo: see if there's a better method of detecting the last item:
			rxRule(["enumfield", "text", "curly.paren.rparen"], ~/(\w+)(\s*)(\})/, "start"),
			rxRule("curly.paren.rparen", ~/\}/, "start"),
		].concat(rBase); //}
		var rEnumValue = [ //{
			rxRule("punctuation.operator", ~/,/, "enum"),
		].concat(rBase); //}
		var rTemplateExpr = [ //{
			rxRule("string", ~/\}/, "pop"),
		].concat(rBase); //}
		var rComment = [ //{
			rule("comment.link", "@\\[" + "[^\\[]*" + "\\]"),
		]; //}
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
			"string.sq": [ //{ GMS1 single-quoted strings
				rxRule("string", ~/.*?[']/, "start"),
				rxRule("string", ~/.+/),
			], //}
			"string.dq": [ //{ GMS1 double-quoted strings
				rxRule("string", ~/.*?["]/, "start"),
				rxRule("string", ~/.+/),
			], //}
			"string.tpl": [ //{ GMLive strings with templates
				rxRule("string", ~/.*?\$\{/, "start"),
				rxRule("string", ~/.*?[`]/, "pop"),
				rxRule("string", ~/.+/),
			], //}
			"string.esc": [ //{ GMS2 strings with escape characters
				rule("string.escape", "\\\\(?:"
					+ "x[0-9a-fA-F]{2}|" // \x41
					+ "u[0-9a-fA-F]{4}|" // \u1234
					// there's also octal which doesn't work (?)
				+ ".)"),
				// (this is to allow escaping linebreaks, which is honestly a strange thing)
				cast { token : "string", regex : "\\\\$", consumeLineEnd : true },
				rule("string", '"|$', "start"),
				rdef("string"),
			], //}
			"comment.line": rComment.concat([ //{
				rxRule("comment.line", ~/$/, "start"),
				rdef("comment.line"),
			]), //}
			"comment.doc.line": rComment.concat([ //{
				rxRule("comment.doc.line", ~/$/, "start"),
				rdef("comment.line"),
			]), //}
			"comment": rComment.concat([
				rxRule("comment", ~/.*?\*\//, "start"),
				rxRule("comment", ~/.+/)
			]),
			"comment.doc": rComment.concat([
				rxRule("comment.doc", ~/.*?\*\//, "start"),
				rxRule("comment.doc", ~/.+/)
			]),
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
	regex:EitherType<String, RegExp>,
	?onMatch:haxe.Constraints.Function,
	?next: String,
	?nextState: String,
	?push:EitherType<String, Array<AceLangRule>>,
};
