package ace;
import ace.AceWrap;
import gml.GmlAPI;
import gml.*;
import parsers.GmlExtCoroutines;
import parsers.GmlKeycode;
import gml.GmlVersion;
import js.RegExp;
import tools.Dictionary;
import ace.AceMacro.rxRule;
import ace.AceMacro.jsOr;
import ace.AceMacro.jsThis;
import haxe.extern.EitherType;
using tools.NativeString;

/**
 * Syntax highlighting rules for GML.
 * Merging constructor from Ace means that it can't have instance methods,
 * so things get kind of weird.
 * @author YellowAfterlife
 */
@:expose("AceGmlHighlight")
@:keep class AceGmlHighlight {
	@:native("$rules") public var rules:Dynamic;
	public function new() {
		var version = GmlAPI.version;
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
					jsOr(GmlAPI.stdKind[name],
						jsOr(parsers.GmlExtCoroutines.keywordMap[name], fallback)
					)
				)
			);
		}
		//
		inline function token(type:String, value:String):Dynamic {
			return { type: type, value: value };
		}
		//
		inline function getLocalType_1(name:String, scope:String):String {
			var kind:String = null;
			//
			var locals = GmlLocals.currentMap[scope];
			if (locals != null) kind = locals.kind[name];
			//
			if (kind == null) {
				var imports = GmlImports.currentMap[scope];
				if (imports != null) kind = imports.kind[name];
			}
			//
			return kind;
		}
		inline function getLocalType(row:Int, name:String):String {
			if (row != null) {
				var scope = GmlScopes.get(row);
				if (scope != null) {
					return getLocalType_1(name, scope);
				} else return null;
			} else return null;
		}
		//
		var rIdentLocal:AceLangRule = {
			regex: '[a-zA-Z_][a-zA-Z0-9_]*\\b',
			onMatch: function(
				value:String, state:String, stack:Array<String>, line:String, row:Int
			) {
				var type:String = getLocalType(row, value);
				if (type == null) type = getGlobalType(value, "localfield");
				return [token(type, value)];
			},
		};
		/** something.field */
		var rIdentPair:AceLangRule = {
			regex: '([a-zA-Z_][a-zA-Z0-9_]*)(\\s*)(\\.)(\\s*)([a-zA-Z_][a-zA-Z0-9_]*|)',
			onMatch: function(
				value:String, state:String, stack:Array<String>, line:String, row:Int
			) {
				var values:Array<String> = jsThis.splitRegex.exec(value);
				var object = values[1];
				var field = values[5];
				var objType:String, fdType:String;
				if (object == "global") {
					objType = "keyword";
					fdType = "globalfield";
				} else {
					objType = null;
					fdType = null;
					if (row != null) {
						var scope = GmlScopes.get(row);
						if (scope != null) {
							var imp = GmlImports.currentMap[scope];
							if (imp != null) {
								var ns = imp.namespaces[object];
								if (ns != null) {
									objType = "namespace";
									fdType = jsOr(ns.kind[field], "identifier");
								}
							}
							if (objType == null) {
								objType = getLocalType_1(object, scope);
							}
						}
					}
					if (objType == null) {
						var en = GmlAPI.gmlEnums[object];
						if (en != null) {
							objType = "enum";
							fdType = en.items[field] ? "enumfield" : "enumerror";
						} else {
							objType = getGlobalType(object, "localfield");
							fdType = getGlobalType(field, "field");
						}
					} else if (fdType == null) {
						fdType = getGlobalType(field, "field");
					}
				}
				var tokens:Array<AceToken> = [token(objType, object)];
				if (values[2] != "") tokens.push(token("text", values[2]));
				tokens.push(token("punctuation.operator", values[3]));
				if (values[4] != "") tokens.push(token("text", values[4]));
				tokens.push(token(fdType, field));
				return tokens;
			}
		};
		function mtField(_, field:String) {
			return ["punctuation.operator", "text", getGlobalType(field, "field")];
		}
		function mtEventHead(def, name, col, kind, label) {
			var kindToken:String;
			if (kind != null) {
				var kc = StringTools.fastCodeAt(kind, 0);
				if (kc >= "0".code && kc <= "9".code) {
					kindToken = "constant.numeric";
				} else kindToken = getGlobalType(kind, "identifier");
			} else kindToken = "identifier";
			return [
				"preproc.event",
				"eventname",
				"punctuation.operator",
				kindToken,
				"eventtext"
			];
		}
		function mtIdent(ident:String) {
			return getGlobalType(ident, "localfield");
		}
		function mtImport(_import, _, _pkg:String, _, _in, _, _as) {
			return ["preproc.import",
				"text",
				"importfrom",
				"text",
				"keyword",
				"text",
				_pkg.endsWith(".*") ? "namespace" : "importas",
			];
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
		//
		var rQuotes:AceLangRule = {
			regex: '(\'|")',
			onMatch: function(value:String, state:String, stack:Array<String>, line:String) {
				var top = stack[stack.length - 1];
				if (value == '"') {
					if (state == "pragma.dq") {
						jsThis.next = "start";
						return "punctuation.operator";
					} else {
						jsThis.next = (version == GmlVersion.v2 ? "string.esc" : "string.dq");
						stack.unshift(state);
						stack.unshift(jsThis.next);
						return "string";
					}
				} else {
					if (state == "pragma.sq") {
						jsThis.next = "start";
						return "punctuation.operator";
					} else if (version != GmlVersion.v2) {
						stack.unshift(state);
						stack.unshift("string.sq");
						jsThis.next = "string.sq";
						return "string";
					} else {
						jsThis.next = null;
						return "punctuation.operator";
					}
				}
			}
		};
		var rPragma_call:AceLangRule = {
			regex: '(gml_pragma)(\\s*)(\\()(\\s*)' +
				'("global"|\'global\')(\\s*)(,)(\\s*)("|\'|@"|@\')',
			onMatch: function(value:String, state:String, stack:Array<String>, line:String) {
				var values:Array<String> = jsThis.splitRegex.exec(value);
				jsThis.next = values[9].indexOf('"') >= 0 ? "pragma.dq" : "pragma.sq";
				return [
					token("function", values[1]),
					token("text", values[2]),
					token("paren.lparen", values[3]),
					token("text", values[4]),
					token("string", values[5]),
					token("text", values[6]),
					token("punctuation.operator", values[7]),
					token("text", values[8]),
					token("punctuation.operator", values[9]),
				];
			},
			next: "pragma",
		};
		var rBase:Array<AceLangRule> = [ //{ comments and preprocessors
			rQuotes,
			rxRule(["comment", "comment.preproc.region", "comment.regionname"],
				~/(\/\/)(#(?:end)?region[ \t]*)(.*)$/),
			rxRule("comment.doc.line", ~/\/\/\/$/),
			rxRule("comment.doc.line", ~/\/\/\//, "comment.doc.line"),
			rxRule("comment.line", ~/\/\/$/),
			rxRule("comment.line", ~/\/\//, "comment.line"),
			rxRule("comment.doc", ~/\/\*\*/, "comment.doc"),
			rxRule("comment", ~/\/\*/, "comment"),
			rxRule(["preproc.define", "scriptname"], ~/^(#define[ \t]+)(\w+)/),
			rxRule(["preproc.event", "eventname", "punctuation.operator", "eventkeyname", "eventnote"],
				~/^(#event[ \t]+)(keyboard|keypress|keyrelease)(\s*:\s*)(\w+)(.*)/),
			//                      1event       2type   3: 4ctx     5label
			rxRule(mtEventHead, ~/^(#event[ \t]+)(\w+)(?:(:)(\w+)?)?((?:\s+.+)?)/),
			rxRule(["preproc.moment", "momenttime", "momentname"], ~/^(#moment[ \t]+)(\d+)(.*)/),
			rxRule(["preproc.macro", "macroname"], ~/(#macro[ \t]+)(\w+)/),
			rule(mtImport, "(#import\\b)"
				+ "([ \t]*)"
				+ "([\\w.]+\\*?)" // com.pkg[.*]
				+ "([ \t]*)"
				+ "((?:\\b(?:as|in)\\b)?)" // in
				+ "([ \t]*)"
				+ "((?:\\w+)?)" // alias
			),
			rxRule(["preproc.import", "string.importpath"], ~/(#import\s+)("[^"]*"|'[^']*')/),
			rxRule("preproc.import", ~/#import\b/),
			rxRule("preproc.args", ~/#args\b/),
			rxRule("preproc.gmcr", ~/#gmcr\b/),
		]; //}
		if (version == GmlVersion.live) rBase.unshift(rTpl);
		if (version == GmlVersion.v2) { // regions
			rBase.push(rxRule(["preproc.region", "regionname"], ~/(#region[ \t]*)(.*)/));
			rBase.push(rxRule(["preproc.region", "regionname"], ~/(#endregion[ \t]*)(.*)/));
		} else {
			rBase.push(rxRule(["preproc.section", "sectionname"], ~/^(#section[ \t]*)(.*)/));
		}
		if (version == GmlVersion.v2) {
			rBase.push(rpush("string", '@"', "string.dq"));
			rBase.push(rpush("string", "@'", "string.sq"));
		}
		if (version == GmlVersion.live) { // template strings
			rBase.push({
				token: "string",
				regex: "`",
				push: [
					//rpush("quasi.paren.lparen", "\\${", "start"),
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
			rxRule(function(goto, _, label) {
				if (GmlExtCoroutines.enabled) {
					return ["keyword", "text", "flowlabel"];
				} else return [mtIdent(goto), "text", mtIdent(label)];
			}, ~/(goto|label)(\s+)(\w+)/),
			rPragma_call,
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
		//
		var rEnum = [ //{
			rxRule(["enumfield", "text", "set.operator"], ~/(\w+)(\s*)(=)/, "enumvalue"),
			rxRule(["enumfield", "text", "punctuation.operator"], ~/(\w+)(\s*)(,)/),
			// todo: see if there's a better method of detecting the last item:
			rxRule(["enumfield", "text"], ~/(\w+)(\s*)$/),
			rxRule(["enumfield", "text", "curly.paren.rparen"], ~/(\w+)(\s*)(\})/, "start"),
			rxRule("curly.paren.rparen", ~/\}/, "start"),
		].concat(rBase); //}
		var rEnumValue = [ //{
			rxRule("punctuation.operator", ~/,/, "enum"),
		].concat(rBase); //}
		//
		var rPragma_sq = [].concat(rBase);
		var rPragma_dq = [].concat(rBase);
		//
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
			Reflect.setField(rules, "pragma.sq", rPragma_sq);
			Reflect.setField(rules, "pragma.dq", rPragma_dq);
		} else rules = {
			"start": rBase,
			"enum": rEnum,
			"enumvalue": rEnumValue,
			"tplexpr": rTemplateExpr,
			"pragma.sq": rPragma_sq,
			"pragma.dq": rPragma_dq,
			"string.esc": [ //{ GMS2 strings with escape characters
				rule("string.escape", "\\\\(?:"
					+ "x[0-9a-fA-F]{2}|" // \x41
					+ "u[0-9a-fA-F]{4}|" // \u1234
					// there's also octal which doesn't work (?)
				+ ".)"),
				// (this is to allow escaping linebreaks, which is honestly a strange thing)
				cast { token : "string", regex : "\\\\$", consumeLineEnd : true },
				rule("string", '"|$', "pop"),
				rdef("string"),
			], //}
			"string.sq": [ //{ GMS1 single-quoted strings
				rxRule("string", ~/.*?[']/, "pop"),
				rxRule("string", ~/.+/),
			], //}
			"string.dq": [ //{ GMS1 double-quoted strings
				rxRule("string", ~/.*?["]/, "pop"),
				rxRule("string", ~/.+/),
			], //}
			"string.tpl": [ //{ GMLive strings with templates
				rxRule("string", ~/.*?\$\{/, "start"),
				rxRule("string", ~/.*?[`]/, "pop"),
				rxRule("string", ~/.+/),
			], //}
			"comment.line": rComment.concat([ //{
				rxRule("comment.line", ~/$/, "start"),
				rdef("comment.line"),
			]), //}
			"comment.doc.line": rComment.concat([ //{
				rxRule("comment.doc.line", ~/$/, "start"),
				rdef("comment.doc.line"),
			]), //}
			"comment": rComment.concat([ //{
				rxRule("comment", ~/.*?\*\//, "start"),
				rxRule("comment", ~/.+/)
			]), //}
			"comment.doc": rComment.concat([ //{
				rxRule("comment.doc", ~/.*?\*\//, "start"),
				rxRule("comment.doc", ~/.+/)
			]), //}
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
