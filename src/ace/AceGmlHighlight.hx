package ace;
import ace.AceWrap;
import ace.extern.*;
import ace.gml.AceGmlDocHint;
import ace.gml.AceGmlHighlightIdents;
import ace.gml.AceGmlState;
import editors.EditCode;
import file.kind.gml.KGmlSearchResults;
import file.kind.misc.KMarkdown;
import gml.GmlAPI;
import gml.GmlImports;
import gml.*;
import file.FileKind;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTools;
import synext.GmlExtCoroutines;
import parsers.GmlKeycode;
import gml.GmlVersion;
import js.lib.RegExp;
import synext.GmlExtMFunc;
import tools.Dictionary;
import ace.AceMacro.rxRule;
import ace.AceMacro.rxPush;
import ace.AceMacro.jsOr;
import ace.AceMacro.jsOrx;
import ace.AceMacro.jsThis;
import ace.extern.AceLangRule;
import ace.raw.*;
import haxe.extern.EitherType;
import tools.HighlightTools.*;
import tools.JsTools;
import ui.Preferences;
using tools.NativeString;
using tools.NativeArray;

/**
 * Syntax highlighting rules for GML.
 * Merging constructor from Ace means that it can't have instance methods,
 * so things get kind of weird.
 * @author YellowAfterlife
 */
@:expose("AceGmlHighlight")
@:keep class AceGmlHighlight extends AceHighlight {
	public static var useBracketDepth:Bool = (function() {
		return Main.document.documentElement.getAttribute("data-theme-uses-bracket-depth") != null;
	})();
	public static function makeRules(editor:EditCode, ?version:GmlVersion):AceHighlightRuleset {
		if (version == null) version = GmlAPI.version;
		var rules:AceHighlightRuleset = null;
		var fakeMultiline:Bool = false;
		var fieldDef = "localfield";
		if (Std.is(editor.kind, KGmlSearchResults)) fakeMultiline = true;
		if (Std.is(editor.kind, KMarkdown)) fieldDef = "md-pre-gml";
		//
		function rwnext(ruleToCopy:AceLangRule, newNext:String):AceLangRule {
			return { token: ruleToCopy.token, regex: ruleToCopy.regex, next: newNext };
		}
		// #mfunc versions use "identifier" instead of normal default field token
		var rIdentLocal:AceLangRule = AceGmlHighlightIdents.genIdent(editor, false, fieldDef);
		var rIdentLocalMFunc:AceLangRule = AceGmlHighlightIdents.genIdent(editor, true, fieldDef);
		var rIdentPair = AceGmlHighlightIdents.genIdentPair(editor, false, fieldDef);
		var rIdentPairMFunc = AceGmlHighlightIdents.genIdentPair(editor, true, fieldDef);
		//
		function mtEventHead(def, _, name, col, kind, label) {
			var kindToken:String;
			if (kind != null) {
				var kc = StringTools.fastCodeAt(kind, 0);
				if (kc >= "0".code && kc <= "9".code) {
					kindToken = "numeric";
				} else {
					kindToken = AceGmlHighlightIdents.getGlobalType(kind, "identifier");
				}
			} else kindToken = "identifier";
			return [
				"preproc.event",
				"text",
				"eventname",
				"punctuation.operator",
				kindToken,
				"eventtext"
			];
		}
		function mtField(_, _, field:String) {
			return ["punctuation.operator", "text", AceGmlHighlightIdents.getGlobalType(field, "field")];
		}
		function mtIdent(ident:String) {
			return AceGmlHighlightIdents.getGlobalType(ident, fieldDef);
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
			onMatch: function(value:String, state:AceLangRuleState, stack:Array<String>, line:String, row) {
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
					stack.unshift(current);
					stack.unshift(jsThis.nextState);
				}
				return jsThis.nextState;
			}
		};
		var rDocHint = {
			regex: JsTools.rx(~/(\/\/\/\s*)(@hint\b)(\s*)(.*)/),
			onMatch: AceGmlDocHint.match,
		};
		//
		var rDefine = rxRule(["preproc.define", "scriptname"], ~/^(#define[ \t]+)(\w+)/);
		var rTarget = rxRule(["preproc.target"], ~/^(#target[ \t]+)/);
		var rAction = rxRule(["preproc.action", "actionname"], ~/^(#action\b[ \t]*)(\w*)/);
		var rKeyEvent = rulePairs([
			"^#event", "preproc.event",
			"[ \\t]+", "text",
			"keyboard|keypress|keyrelease", "eventname",
			"\\s*:\\s*", "eventsep.punctuation.operator", // has prefix to filter AC on
			"\\w*", "eventkeyname",
			".*", "eventtext",
		]);
		var rEvent = rxRule(mtEventHead, ~/^(#event)([ \t]+)(\w+)(?:(:)(\w+)?)?((?:\b.+)?)/);
		var rEventBlank = rxRule(["preproc.event", "eventname"], ~/^(#event)([ \t]*)/);
		var rMoment = rxRule(
			["preproc.moment", "momenttime", "momentname"],
			~/^(#moment[ \t]+)(\d+)(.*)/
		);
		var rSection = rxRule(["preproc.section", "sectionname"], ~/^(#section[ \t]*)(.*)/);
		var commentDocLineType:String = "comment.doc.line";
		//
		var rGmlComment = (fakeMultiline
			? rxRule(["comment", "comment.preproc", "comment"], ~/(\/\*(?:\/\/)?\s*)(#gml)(.*?(?:\*\/|$))/)
			: rxPush(["comment", "comment.preproc"],            ~/(\/\*(?:\/\/)?\s*)(#gml)/, "gml.comment.gml")
		);
		var rBase:Array<AceLangRule> = [ //{ comments and preprocessors
			rxRule(["comment", "comment.preproc.region", "comment.regionname"],
				~/(\/\/)(#(?:region|endregion|mark)\b)(.*)$/),
			rxRule("comment.doc.line", ~/\/\/\/$/), // a blank doc-line
			
			rDocHint,
			
			rxRule(function(s) { // a doc-line starting with X and having no @[tags]
				return "comment.doc.line.startswith_" + s;
			}, ~/\/\/\/([^\s@]+)(?:(?!@\[).)*$/),
			rxPush(function(s) { // a doc-line starting with X
				commentDocLineType = "comment.doc.line.startswith_" + s;
				return commentDocLineType;
			}, ~/\/\/\/([^\s@]+)/, "gml.comment.doc.line"),
			rxPush(function(_) { // a regular doc-line
				commentDocLineType = "comment.doc.line";
				return "comment.doc.line";
			}, ~/\/\/\//, "gml.comment.doc.line"),
			//
			rxRule("comment.line", ~/\/\/$/),
			rxPush("comment.line", ~/\/\//, "gml.comment.line"),
			rGmlComment,
			rxRule("comment.doc", ~/\/\*\*\//), // /**/
			fakeMultiline
				? rxRule("comment.doc", ~/\/\*\*.*?(?:\*\/|$)/)
				: rxPush("comment.doc", ~/\/\*\*/, "gml.comment.doc"),
			fakeMultiline
				? rxRule("comment", ~/\/\*.*?(?:\*\/|$)/)
				: rxPush("comment", ~/\/\*/, "gml.comment"),
			//
			rDefine, rAction, rKeyEvent, rEvent, rEventBlank, rMoment, rTarget,
			rxRule(["keyword", "text", "field"], ~/(static)(\s+)([_a-zA-Z]\w*)/),
			//{ macros
			rpushPairs([
				"#macro", "preproc.macro",
				"\\s+", "text",
				"\\w+", "configname",
				"\\s*", "text",
				":", "punctuation.operator",
				"\\s*", "text",
				"\\w+", "macroname",
			], "gml.mfunc"),
			rpushPairs([
				"#macro", "preproc.macro",
				"\\s+", "text",
				"\\w+", "macroname",
			], "gml.mfunc"),
			rxRule("preproc.macro", ~/#macro\b/),
			rpushPairs([
				"#mfunc", "preproc.mfunc",
				"\\s+", "text",
				"\\w+", "macroname",
				"\\s*", "text",
				"\\(", "paren.lparen",
			], "gml.mfunc.decl"),
			rxRule(["preproc.mfunc", "text", "macroname"], ~/(#mfunc)(\s+)(\w+)/),
			rxRule("preproc.mfunc", ~/#mfunc\b/),
			//}
			rulePairs([
				"#import\\s+", "preproc.import",
				"\"[^\"]*\"|'[^']*'", "string.importpath"
			]),
			rxPush("preproc.import", ~/#import\b/, "gml.import"),
			rxRule("preproc.args", ~/#args\b/),
			//
			rxRule(["preproc.hyper", "comment.hyper"], ~/(#hyper\b)(.*)/),
			rxRule(["preproc.lambda", "text", "scriptname"], ~/(#(?:lambda|lamdef)\b)([ \t]*)(\w*)/),
			rxRule("preproc.gmcr", ~/#gmcr\b/),
		]; //}
		if (version.config.hasRegions) { // regions
			rBase.push(rxRule(["preproc.region", "regionname"], ~/(#region[ \t]*)(.*)/));
			rBase.push(rxRule(["preproc.region", "regionname"], ~/(#endregion[ \t]*)(.*)/));
		}
		rBase.push(rSection); // only used in v2 for object info
		if (version.hasStringEscapeCharacters()) {
			rBase.push(rxPush("string", ~/"/, "gml.string.esc"));
		} else {
			rBase.push(rxPush("string", ~/"/, "gml.string.dq"));
		}
		if (version.hasSingleQuoteStrings()) {
			rBase.push(rxPush("string", ~/'/, "gml.string.sq"));
		}
		if (version.hasLiteralStrings()) {
			rBase.push(rxPush("string", ~/@"/, "gml.string.dq"));
			rBase.push(rxPush("string", ~/@'/, "gml.string.sq"));
		}
		if (version.hasTemplateStrings()) {
			rBase.push(rxPush("string", ~/`/, "gml.string.tpl"));
		}
		//{ braces
		var rCurlyOpen:AceLangRule = {
			regex: "\\{",
			onMatch: function(value:String, state:AceLangRuleState, stack, line, row) {
				if (useBracketDepth) {
					return "curly.paren.lparen.depth" + AceGmlState.getDepth(state);
				}
				return "curly.paren.lparen";
			},
			next: function(current:AceLangRuleState, stack:Array<String>) {
				if (useBracketDepth) {
					return AceGmlState.adjustDepth(current, 1);
				}
				return current;
			}
		};
		var rCurlyClose:AceLangRule = {
			regex: "\\}",
			onMatch: function(value:String, state:AceLangRuleState, stack, line, row) {
				if (useBracketDepth) {
					return "curly.paren.rparen.depth" + (AceGmlState.getDepth(state) - 1);
				}
				return "curly.paren.rparen";
			},
			next: function(current:AceLangRuleState, stack:Array<String>) {
				if (useBracketDepth) {
					return AceGmlState.adjustDepth(current, -1);
				}
				return current;
			}
		};
		//}
		var rParOpen:AceLangRule;
		if (Preferences.current.hashColorLiterals) {
			rBase = rBase.concat([
				rxRule(["square.paren.lparen", "text"], ~/\[#/),
				rxRule("numeric", ~/#[0-9a-fA-F]{6,6}\b/)
			]);
		}
		rBase = rBase.concat([ //{
			rxRule("numeric", ~/(?:\$|0x)[0-9a-fA-F]*/), // $c0ffee
			rxRule("numeric", ~/\d+(?:\.\d*)?/), // 42.5 (GML has no E# suffixes)
			rxRule("constant.boolean", ~/(?:true|false)\b/),
			rxPush(["keyword", "text", "enum"], ~/(enum)(\s+)(\w+)/, "gml.enum"),
			rxRule(function(goto, _, label) {
				if (GmlExtCoroutines.enabled) {
					return ["keyword", "text", "flowlabel"];
				} else return [mtIdent(goto), "text", mtIdent(label)];
			}, ~/(goto|label)(\s+)(\w+)/),
			rPragma_call,
			//
			rIdentPair,
			rIdentLocal,
			rxRule(mtField, ~/(\.)(\s*)([a-zA-Z_][a-zA-Z0-9_]*)/),
			rxRule(mtIdent, ~/[a-zA-Z_][a-zA-Z0-9_]*\b/), // todo: consistently shadowed by rIdentLocal?
			//
			rxRule("operator", ~/==/),
			rxRule("set.operator", ~/=|\+=|\-=|\*=|\/=|%=|&=|\|=|\^=|<<=|>>=/),
			rxRule("operator", ~/!|%|&|@|\*|\-\-|\-|\+\+|\+|~|!=|<=|>=|<>|<|>|!|&&|\|\|/),
			rxRule("punctuation.operator", ~/\?|:|,|;|\./),
			rCurlyOpen,
			rCurlyClose,
			rxRule("square.paren.lparen", ~/\[/),
			rxRule("square.paren.rparen", ~/\]/),
			rParOpen = rxRule("paren.lparen", ~/\(/),
			rxRule("paren.rparen", ~/\)/),
			rdef("text"),
		]); //}
		if (GmlAPI.stdKind["new"] == "keyword") {
			var rxCtr = rxRule(["paren.rparen", "text", "keyword"], ~/(\))(\s*)(constructor)/);
			rBase.insertBefore(rxCtr, rParOpen);
		}
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
			rxRule("curly.paren.rparen", ~/\}/, function(currentState, stack:Array<AceLangRuleState>) {
				// double-pop because we must both exit gml.enum.value and gml.enum
				stack.shift();
				stack.shift();
				if (stack.length > 0) {
					return stack.shift();
				} else return AceGmlState.changeState(currentState, "start");
			}),
		].concat(rBase); //}
		//{ comments
		var rCommentPop:Array<AceLangRule> = [
			rwnext(rDefine, "pop"),
			rwnext(rAction, "pop"),
			rwnext(rSection, "pop"),
			rwnext(rMoment, "pop"),
			rwnext(rKeyEvent, "pop"),
			rwnext(rEvent, "pop"),
			rwnext(rTarget, "pop"),
		];
		var rComment = [
			rule("comment.link", "@\\[" + "[^\\[]*" + "\\]"),
			rxRule("comment.link.url", // https://stackoverflow.com/a/3809435/5578773
				~/https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)/
			),
		];
		function getNamespaceType(name:String) {
			var ns = GmlAPI.gmlNamespaces[name];
			return JsTools.orx(
				JsTools.nca(ns, ns.isObject ? "asset.object" : "namespace"),
				GmlAPI.gmlKind[name],
				"text"
			);
		}
		//}
		//{ string-based
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
		var rString_tpl_id:AceLangRule = {
			regex: "(\\$)([a-zA-Z_]\\w*)",
			onMatch: function(
				value:String, state:AceLangRuleState, stack:Array<String>, line:String, row:Int
			) {
				value = value.substring(1);
				var type:String = AceGmlHighlightIdents.getLocalType(editor, row, value, true);
				if (type == null) type = AceGmlHighlightIdents.getGlobalType(value, fieldDef);
				return [rtk("string", "$"), rtk(type, value)];
			},
		};
		var rString_tpl = [
			rxPush(["string", "curly.paren.lparen"], ~/(\$)(\{)/, "gml.tpl"),
			rString_tpl_id,
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
		//}
		//{ #mfunc
		var rMFunc_decl:Array<AceLangRule> = [
			rxRule("identifier", ~/(?:[a-zA-Z_]\w*|\.\.\.)/),
			rxRule("punctuation.operator", ~/,/),
			rxRule("text", ~/$/, "pop"),
			{
				regex: '(\\))(\\s*)(as)(\\s+)("[^"]*?(?:"|$))',
				onMatch: function(value:String, curr:String, st, line:String, row) {
					var values = (jsThis:AceLangRule).splitRegex.exec(value);
					var t = values[5];
					if (t.endsWith('"')) {
						t = t.substring(1, t.length - 1);
					} else t = t.substring(1, t.length);
					return [
						rtk("paren.rparen", values[1]),
						rtk("text", values[2]),
						rtk("keyword", values[3]),
						rtk("text", values[4]),
						rtk(t, values[5]),
					];
				},
				next: "gml.mfunc",
			},
			rulePairs([
				"\\)", "paren.rparen",
				"\\s*", "text",
				"as\\b", "keyword",
			], "gml.mfunc"),
			rxRule("paren.rparen", ~/\)/, "gml.mfunc"),
		];
		// EOL exits the mfunc state unless it's escaped
		function rMFuncEOL_pop(current, stack:Array<String>) {
			stack.shift();
			return jsOrx(stack.shift(), "start");
		}
		var rMFuncEOL:AceLangRule = null;
		rMFuncEOL = {
			regex: "$",
			onMatch: function(value:String, currentState:AceLangRuleState, stack:Array<String>, line:String, row) {
				rMFuncEOL.next = line.endsWith("\\") ? null : rMFuncEOL_pop;
				return "text";
			}
		};
		//
		var rMFunc = [
			rMFuncEOL,
			rule(["operator", "constant"], synext.GmlExtMFunc.magicRegex),
		].concat(rBase);
		rMFunc.replaceOne(rIdentLocal, rIdentLocalMFunc);
		rMFunc.replaceOne(rIdentPair, rIdentPairMFunc);
		//}
		//
		function pop2(c:AceLangRuleState, st:Array<AceLangRuleState>) {
			st.shift();
			st.shift();
			st.shift();
			return JsTools.or(st.shift(), "start");
		}
		rules = {
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
			"gml.type.params": [ // Type<param>
				rxPush("operator", ~/</, "gml.type.params"),
				rxRule("operator", ~/>/, "pop")
			].concat(rBase),
			"gml.mfunc.decl": rMFunc_decl,
			"gml.mfunc": rMFunc,
			"gml.comment.line": rComment.concat([ //{
				rxRule("comment.line", ~/$/, "pop"),
				rdef("comment.line"),
			]), //}
			"gml.comment.doc.line": rComment.concat([ //{
				rxRule(function(meta, _, type1, _, keyword, _, type2) {
					var t1 = getNamespaceType(type1);
					var t2 = getNamespaceType(type2);
					var dt = commentDocLineType;
					return ["comment.meta", dt, t1, dt, "keyword", dt, t2];
				}, ~/(@hint)(\s+)(\w+)(\s+)(extends|implements)(\b\s*)(\w*)/),
				rxPush("curly.paren.lparen", ~/\{$/),
				rxPush("curly.paren.lparen", ~/\{/, "gml.comment.doc.curly"),
				rule("comment.meta", "@(?:\\w+|$)"),
				rxRule((_) -> commentDocLineType, ~/$/, "pop"),
				rdef("comment.doc.line"),
			]), //}
			"gml.comment.doc.curly": [
				rxRule(function(id) {
					if (GmlAPI.gmlNamespaces.exists(id)) return "namespace";
					return JsTools.or(GmlTypeTools.kindMap[id], "identifier");
				}, ~/\w+/),
				rxRule("punctuation.operator", ~/[,?]/),
				rxRule("operator", ~/[<>]/),
				rxRule("square.paren.lparen", ~/\[/),
				rxRule("square.paren.rparen", ~/\]/),
				rxRule("paren.lparen", ~/\(/),
				rxRule("paren.rparen", ~/\)/),
				rxRule("curly.paren.rparen", ~/\}$/, pop2),
				rxRule("curly.paren.rparen", ~/\}/, "pop"),
				rxRule("text", ~/$/, pop2),
				rdef("text"),
			],
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
		//
		if (ui.Preferences.current.codeLiterals && (version.hasLiteralStrings() || version.hasSingleQuoteStrings())) {
			function addShaderBlock(substart:String, subset:AceHighlightRuleset) {
				var start = subset["start"].slice(0);
				start.unshift(rxRule("string", ~/'/, "pop"));
				for (key in subset.keys()) if (key != "start") rules[key] = subset[key];
				rules[substart] = start;
			}
			addShaderBlock("gml.string.hlsl", shaders.ShaderHighlight.makeRules(null, HLSL));
			addShaderBlock("gml.string.glsl", shaders.ShaderHighlight.makeRules(null, GLSL));
			rules["gml.string.gml"] = [rxRule("string", ~/'/, "pop")].concat(rBase);
			var sfx = version.hasSingleQuoteStrings() ? "'" : "@'";
			inline function add(mode:String) {
				rBase.insertBefore(rule(
					["comment", "string"],
					"(/\\*" + mode + "\\*/)(" + sfx + ")",
					"gml.string." + mode
				), rGmlComment);
			}
			add("hlsl");
			add("glsl");
			add("gml");
		}
		//
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
