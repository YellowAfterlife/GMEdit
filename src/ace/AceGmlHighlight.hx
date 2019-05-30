package ace;
import ace.AceWrap;
import ace.extern.*;
import editors.EditCode;
import file.kind.gml.KGmlSearchResults;
import file.kind.misc.KMarkdown;
import gml.GmlAPI;
import gml.GmlImports;
import gml.*;
import file.FileKind;
import parsers.GmlExtCoroutines;
import parsers.GmlKeycode;
import gml.GmlVersion;
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
 * Syntax highlighting rules for GML.
 * Merging constructor from Ace means that it can't have instance methods,
 * so things get kind of weird.
 * @author YellowAfterlife
 */
@:expose("AceGmlHighlight")
@:keep class AceGmlHighlight extends AceHighlight {
	public static function makeRules(editor:EditCode, ?version:GmlVersion):AceHighlightRuleset {
		if (version == null) version = GmlAPI.version;
		var fakeMultiline:Bool = false;
		var fieldDef = "localfield";
		if (Std.is(editor.kind, KGmlSearchResults)) fakeMultiline = true;
		if (Std.is(editor.kind, KMarkdown)) fieldDef = "text";
		//
		function rwnext(ruleToCopy:AceLangRule, newNext:String):AceLangRule {
			return { token: ruleToCopy.token, regex: ruleToCopy.regex, next: newNext };
		}
		//
		inline function getGlobalType(name:String, fallback:String) {
			return jsOrx(
				GmlAPI.gmlKind[name],
				GmlAPI.extKind[name],
				GmlAPI.stdKind[name],
				parsers.GmlExtCoroutines.keywordMap[name],
				fallback
			);
		}
		//
		inline function getLocalType_1(name:String, scope:String):String {
			var kind:String = null;
			//
			var lambdas = editor.lambdas[scope];
			if (lambdas != null) kind = lambdas.kind[name];
			//
			if (kind == null) {
				var locals = editor.locals[scope];
				if (locals != null) kind = locals.kind[name];
				//
				if (kind == null) {
					var imports = editor.imports[scope];
					if (imports != null) kind = imports.kind[name];
				}
			}
			//
			return kind;
		}
		inline function getLocalType(row:Int, name:String):String {
			if (row != null) {
				var scope = editor.session.gmlScopes.get(row);
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
				if (type == null) type = getGlobalType(value, fieldDef);
				return [rtk(type, value)];
			},
		};
		/// something.field
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
					var en:GmlEnum;
					if (row != null) {
						var scope = editor.session.gmlScopes.get(row);
						if (scope != null) {
							var imp = editor.imports[scope];
							var ns:GmlNamespace;
							if (imp != null) {
								ns = imp.namespaces[object];
								if (ns != null) {
									objType = "namespace";
									fdType = jsOr(ns.kind[field], "identifier");
								} else {
									var e1 = imp.longenEnum[object];
									if (e1 != null) {
										en = GmlAPI.gmlEnums[e1];
										if (en != null) {
											objType = "enum";
											fdType = en.items[field] ? "enumfield" : "enumerror";
										}
									}
								}
							}
							if (objType == null) {
								objType = getLocalType_1(object, scope);
								if (objType == "local" && imp != null) {
									var lt = imp.localTypes[object];
									ns = imp.namespaces[lt];
									if (ns != null) {
										fdType = jsOr(ns.kind[field], "typeerror");
									} else {
										en = GmlAPI.gmlEnums[lt];
										if (en != null) {
											fdType = en.items[field] ? "enumfield" : "enumerror";
										} else fdType = "identifier";
									}
								}
							}
						}
					}
					if (objType == null) {
						en = GmlAPI.gmlEnums[object];
						if (en != null) {
							objType = "enum";
							fdType = en.items[field] ? "enumfield" : "enumerror";
						} else {
							objType = getGlobalType(object, fieldDef);
							fdType = getGlobalType(field, "field");
						}
					} else if (fdType == null) {
						fdType = getGlobalType(field, "field");
					}
				}
				var tokens:Array<AceToken> = [rtk(objType, object)];
				if (values[2] != "") tokens.push(rtk("text", values[2]));
				tokens.push(rtk("punctuation.operator", values[3]));
				if (values[4] != "") tokens.push(rtk("text", values[4]));
				tokens.push(rtk(fdType, field));
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
					kindToken = "numeric";
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
			return getGlobalType(ident, fieldDef);
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
		var rPragma_call:AceLangRule = {
			regex: '(gml_pragma)(\\s*)(\\()(\\s*)' +
				'("global"|\'global\')(\\s*)(,)(\\s*)(@?)("|\')',
			onMatch: function(value:String, state:String, stack:Array<String>, line:String) {
				var values:Array<String> = jsThis.splitRegex.exec(value);
				stack.push(state);
				jsThis.nextState = values[10] == '"' ? "gml.pragma.dq" : "gml.pragma.sq";
				return [
					rtk("function", values[1]),
					rtk("text", values[2]),
					rtk("paren.lparen", values[3]),
					rtk("text", values[4]),
					rtk("string", values[5]),
					rtk("text", values[6]),
					rtk("punctuation.operator", values[7]),
					rtk("text", values[8]),
					rtk("punctuation.operator", values[9]),
					rtk("string", values[10]),
				];
			},
			next: cast function(current, stack) {
				if (current != "start" || stack.length > 0) {
					stack.unshift(jsThis.nextState, current);
				}
				return jsThis.nextState;
			}
		};
		//
		var rDefine = rxRule(["preproc.define", "scriptname"], ~/^(#define[ \t]+)(\w+)/);
		var rTarget = rxRule(["preproc.target"], ~/^(#target[ \t]+)/);
		var rAction = rxRule(["preproc.action", "actionname"], ~/^(#action\b[ \t]*)(\w*)/);
		var rKeyEvent = rxRule(
			["preproc.event", "eventname", "punctuation.operator", "eventkeyname", "eventnote"],
			~/^(#event[ \t]+)(keyboard|keypress|keyrelease)(\s*:\s*)(\w+)(.*)/
		);
		var rEvent = rxRule(mtEventHead, ~/^(#event[ \t]+)(\w+)(?:(:)(\w+)?)?((?:\b.+)?)/);
		var rMoment = rxRule(
			["preproc.moment", "momenttime", "momentname"],
			~/^(#moment[ \t]+)(\d+)(.*)/
		);
		var rSection = rxRule(["preproc.section", "sectionname"], ~/^(#section[ \t]*)(.*)/);
		var commentDocLineType:String = "comment.doc.line";
		//
		var rBase:Array<AceLangRule> = [ //{ comments and preprocessors
			rxRule(["comment", "comment.preproc.region", "comment.regionname"],
				~/(\/\/)(#(?:end)?region[ \t]*)(.*)$/),
			rxRule("comment.doc.line", ~/\/\/\/$/), // a blank doc-line
			rxRule(function(s) { // a doc-line starting with X and having no @[tags]
				return "comment.doc.line.startswith_" + s;
			}, ~/\/\/\/(\S+)(?:(?!@\[).)*$/),
			rxPush(function(s) { // a doc-line starting with X
				commentDocLineType = "comment.doc.line.startswith_" + s;
				return commentDocLineType;
			}, ~/\/\/\/(\S+)/, "gml.comment.doc.line"),
			rxPush(function(_) { // a regular doc-line
				commentDocLineType = "comment.doc.line";
				return "comment.doc.line";
			}, ~/\/\/\//, "gml.comment.doc.line"),
			rxRule("comment.line", ~/\/\/$/),
			rxPush("comment.line", ~/\/\//, "gml.comment.line"),
			fakeMultiline
				? rxRule(["comment", "comment.preproc", "comment"], ~/(\/\*(?:\/\/)?\s*)(#gml)(.*?(?:\*\/|$))/)
				: rxPush(["comment", "comment.preproc"],            ~/(\/\*(?:\/\/)?\s*)(#gml)/, "gml.comment.gml"),
			fakeMultiline
				? rxRule("comment.doc", ~/\/\*\*.*?(?:\*\/|$)/)
				: rxPush("comment.doc", ~/\/\*\*/, "gml.comment.doc"),
			fakeMultiline
				? rxRule("comment", ~/\/\*.*?(?:\*\/|$)/)
				: rxPush("comment", ~/\/\*/, "gml.comment"),
			rDefine, rAction, rKeyEvent, rEvent, rMoment, rTarget,
			rxRule(["preproc.macro", "configname", "punctuation.operator", "macroname"], ~/(#macro[ \t]+)(\w+)(:)(\w+)/),
			rxRule(["preproc.macro", "macroname"], ~/(#macro[ \t]+)(\w+)/),
			rulePairs([
				"#import\\s+", "preproc.import",
				"\"[^\"]*\"|'[^']*'", "string.importpath"
			]),
			rxPush("preproc.import", ~/#import\b/, "gml.import"),
			rxRule("preproc.args", ~/#args\b/),
			rxRule(["preproc.hyper", "comment.hyper"], ~/(#hyper\b)(.*)/),
			rxRule(["preproc.lambda", "text", "scriptname"], ~/(#(?:lambda|lamdef)\b)([ \t]*)(\w*)/),
			rxRule("preproc.gmcr", ~/#gmcr\b/),
		]; //}
		if (version == GmlVersion.v2) { // regions
			rBase.push(rxRule(["preproc.region", "regionname"], ~/(#region[ \t]*)(.*)/));
			rBase.push(rxRule(["preproc.region", "regionname"], ~/(#endregion[ \t]*)(.*)/));
		}
		rBase.push(rSection); // only used in v2 for object info
		if (version == GmlVersion.v2) {
			rBase.push(rxPush("string", ~/@"/, "gml.string.dq"));
			rBase.push(rxPush("string", ~/@'/, "gml.string.sq"));
			rBase.push(rxPush("string", ~/"/, "gml.string.esc"));
		} else {
			rBase.push(rxPush("string", ~/"/, "gml.string.dq"));
			rBase.push(rxPush("string", ~/'/, "gml.string.sq"));
		}
		if (version.hasTemplateStrings()) {
			rBase.push(rxPush("string", ~/`/, "gml.string.tpl"));
		}
		rBase = rBase.concat([ //{
			rxRule("numeric", ~/(?:\$|0x)[0-9a-fA-F]+\b/), // $c0ffee
			rxRule("numeric", ~/[+-]?\d+(?:\.\d*)?\b/), // 42.5 (GML has no E# suffixes)
			rxRule("constant.boolean", ~/(?:true|false)\b/),
			rxPush(["keyword", "text", "enum"], ~/(enum)(\s+)(\w+)/, "gml.enum"),
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
			rxRule("operator", ~/==/),
			rxRule("set.operator", ~/=|\+=|\-=|\*=|\/=|%=|&=|\|=|\^=|<<=|>>=/),
			rxRule("operator", ~/!|%|&|\*|\-\-|\-|\+\+|\+|~|!=|<=|>=|<>|<|>|!|&&|\|\|/),
			rxRule("punctuation.operator", ~/\?|:|,|;|\./),
			rxRule("curly.paren.lparen", ~/\{/),
			rxRule("curly.paren.rparen", ~/\}/),
			rxRule("square.paren.lparen", ~/\[/),
			rxRule("square.paren.rparen", ~/\]/),
			rxRule("paren.lparen", ~/\(/),
			rxRule("paren.rparen", ~/\)/),
			rdef("text"),
		]); //}
		//
		var rEnum = [ //{
			rxPush(["enumfield", "text", "set.operator"], ~/(\w+)(\s*)(=)/, "gml.enumvalue"),
			rxRule(["enumfield", "text", "punctuation.operator"], ~/(\w+)(\s*)(,)/),
			// todo: need to make an actual push/pop system
			rxRule("comment", ~/\/\/.*$/),
			// todo: see if there's a better method of detecting the last item:
			rxRule(["enumfield", "text"], ~/(\w+)(\s*)$/),
			rxRule(["enumfield", "text", "curly.paren.rparen"], ~/(\w+)(\s*)(\})/, "pop"),
			rxRule("curly.paren.rparen", ~/\}/, "pop"),
		].concat(rBase); //}
		if (fakeMultiline) rEnum.unshift(rxRule("text", ~/$/, "pop"));
		var rEnumValue = [ //{
			rxRule("punctuation.operator", ~/,/, "pop"),
			rxRule("curly.paren.rparen", ~/\}/, function(currentState, stack:Array<String>) {
				// double-pop because we must both exit gml.enum.value and gml.enum
				stack.shift();
				stack.shift();
				if (stack.length > 0) {
					return stack.shift();
				} else return "start";
			}),
		].concat(rBase); //}
		var rCommentPop:Array<AceLangRule> = [
			rwnext(rDefine, "pop"),
			rwnext(rAction, "pop"),
			rwnext(rSection, "pop"),
			rwnext(rMoment, "pop"),
			rwnext(rKeyEvent, "pop"),
			rwnext(rEvent, "pop"),
			rwnext(rTarget, "pop"),
		];
		//
		var rPragma_sq = [rule("string", "'", "pop")].concat(rBase);
		var rPragma_dq = [rule("string", '"', "pop")].concat(rBase);
		var rString_sq = [ // GMS1 single-quoted strings
			rxRule("string", ~/.*?[']/, "pop"),
			rxRule("string", ~/.+/),
		];
		var rString_dq = [ // GMS1 double-quoted strings
			rxRule("string", ~/.*?["]/, "pop"),
			rxRule("string", ~/.+/),
		];
		var rString_tpl = [
			rxPush(["string", "curly.paren.lparen"], ~/(\$)(\{)/, "gml.tpl"),
			rxRule("string", ~/[`]/, "pop"),
			rdef("string"),
		];
		if (fakeMultiline) {
			var eol = rule("string", ".*?$", "pop");
			rPragma_sq.unshift(eol);
			rPragma_dq.unshift(eol);
			rString_sq.insert(1, eol);
			rString_dq.insert(1, eol);
			rString_tpl.insert(1, eol);
		}
		//
		var rComment = [ //{
			rule("comment.link", "@\\[" + "[^\\[]*" + "\\]"),
		]; //}
		//
		var rules = {
			"start": rBase,
			"gml.enum": rEnum,
			"gml.enumvalue": rEnumValue,
			"gml.pragma.sq": rPragma_sq,
			"gml.pragma.dq": rPragma_dq,
			"gml.import": [ //{
				rule("keyword", "(in|as)\\b"),
				rule("impfield", "@\\w+"),
				rule("text", "[ \t]*$", "pop"),
			].concat(rBase), //}
			"gml.string.esc": [ //{ GMS2 strings with escape characters
				rule("string.escape", "\\\\(?:"
					+ "x[0-9a-fA-F]{2}|" // \x41
					+ "u[0-9a-fA-F]{4}|" // \u1234
					// there's also octal which doesn't work (?)
				+ ".)"),
				// (this is to allow escaping linebreaks, which is honestly a strange thing)
				({ token : "string", regex : "\\\\$", consumeLineEnd : true }:AceLangRule),
				rule("string", '"|$', "pop"),
				rdef("string"),
			], //}
			"gml.string.sq": rString_sq,
			"gml.string.dq": rString_dq,
			"gml.string.tpl": rString_tpl,
			"gml.tpl": [ // values inside template strings
				rxPush("curly.paren.lparen", ~/\{/, "gml.tpl"),
				rxRule("curly.paren.rparen", ~/\}/, "pop")
			].concat(rBase),
			"gml.comment.line": rComment.concat([ //{
				rxRule("comment.line", ~/$/, "pop"),
				rdef("comment.line"),
			]), //}
			"gml.comment.doc.line": rComment.concat([ //{
				rxRule((_) -> commentDocLineType, ~/.*$/, "pop"),
				rdef("comment.doc.line"),
			]), //}
			"gml.comment": rComment.concat(rCommentPop).concat([ //{
				rxRule("comment", ~/.*?\*\//, "pop"),
				rxRule("comment", ~/.+/)
			]), //}
			"gml.comment.doc": rComment.concat(rCommentPop).concat([
				rxRule("comment.doc", ~/.*?\*\//, "pop"),
				rxRule("comment.doc", ~/.+/)
			]),
			"gml.comment.gml": rCommentPop.concat([
				rxRule("comment", ~/.*?\*\//, "pop"),
			]).concat(rBase),
		};
		return rules;
	}
	public function new() {
		super();
		rules = makeRules(EditCode.currentNew);
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
