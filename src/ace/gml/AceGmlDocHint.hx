package ace.gml;
import ace.extern.AceHighlightRuleset;
import ace.extern.AceLangRule;
import ace.AceMacro.rxRule;
import ace.AceMacro.rxPush;
import tools.HighlightTools.*;
import tools.JsTools;
import ace.extern.AceLangRuleDef;
import ace.extern.AceLangRuleDef.*;
using ace.extern.AceLangRuleDefTools;

/**
 * ...
 * @author YellowAfterlife
 */
class AceGmlDocHint {
	public static inline var sBase:String = "gml.comment.doc.hint";
	public static function add(out:AceHighlightRuleset, rComment:Array<AceLangRule>) {
		var tBase = "comment.doc.line";
		var tOperator = "operator";
		var tPunctOp = "punctuation.operator";
		var tNamespace = "namespace";
		var tKeyword = "keyword";
		//
		var dSpace = Token("\\s+", tBase);
		var dOptSpace = Token("\\s*", tBase);
		var dNew = [OptGroup([
			Token("new\\b", "keyword"),
			dOptSpace,
		])];
		var dType = [
			Token("\\w+", tNamespace),
			OptGroup([
				Token("<", tOperator),
				Token("[^>*]", tNamespace),
				Token(">?", tOperator),
			]),
		];
		var dFull = dNew.concat(dType).concat([
			OptGroup([
				dOptSpace,
				Token("[:.]", tPunctOp),
				dOptSpace,
				Token("\\w*", "field"),
			]),
		]);
		var dAuto = dNew.concat([
			Token("[:.]", tPunctOp),
			dOptSpace,
			Token("\\w*", "field"),
		]);
		var dExtends = dType.concat([
			dOptSpace,
			Token("\\b(?:extends|implements)\\b", "keyword"),
			dOptSpace,
			Token("\\S*", "namespace"),
		]);
		var dCall = [dOptSpace, Token("\\(", "paren.lparen")];
		var dEOL = [Token("$", tBase)];
		//
		var sArgs = sBase + ".args";
		var sRest = sBase + ".rest";
		out[sBase] = [
			rxRule("curly.paren.lparen", ~/\{$/, "pop"),
			rxPush("curly.paren.lparen", ~/\{/, "gml.comment.doc.curly"),
			
			dExtends.concat(dEOL).toRule({next: "pop"}),
			dExtends.toRule({next: sRest}),
			
			dFull.concat(dEOL).toRule({next: "pop"}),
			dFull.concat(dCall).toRule({next: sArgs}),
			dFull.toRule({next: sRest}),
			
			dAuto.concat(dEOL).toRule({next: "pop"}),
			dAuto.concat(dCall).toRule({next: sArgs}),
			dAuto.toRule({next: sRest}),
			
			//rawRulePairs(pNew.concat(pCall), sArgs), // `@hint new(args)` or `@hint (args)` - no use?
			rxRule(tBase, ~/$/, "pop"),
			rdef(tBase),
		];
		
		//
		var dArgClose = [
			Token("\\)", "paren.rparen"),
			OptGroup([
				Token("->", tOperator),
				OptToken("\\S+", tNamespace),
			]),
		];
		out[sArgs] = [
			dArgClose.concat(dEOL).toRule({next: "pop"}),
			dArgClose.toRule({next: sRest}),
			rxRule("local", ~/\w+/),
			rxRule("punctuation.operator", ~/,/),
			rxRule(tBase, ~/$/, "pop"),
			rdef(tBase),
		];
		out[sRest] = rComment.concat([
			rxRule(tBase, ~/$/, "pop"),
			rdef(tBase),
		]);
	}
}