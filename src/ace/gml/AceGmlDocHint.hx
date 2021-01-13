package ace.gml;
import ace.extern.AceHighlightRuleset;
import ace.extern.AceLangRule;
import ace.AceMacro.rxRule;
import ace.AceMacro.rxPush;
import tools.HighlightTools.*;
import tools.JsTools;

/**
 * ...
 * @author YellowAfterlife
 */
class AceGmlDocHint {
	public static inline var sBase:String = "gml.comment.doc.hint";
	public static function add(out:AceHighlightRuleset, rComment:Array<AceLangRule>) {
		// Man, these rules are so hard to write. If only there was an easier way...
		var cdl = "comment.doc.line";
		var pNew = ["(?:(new\\b)", "keyword", "(\\s*))?", cdl];
		var pType = [
			"(\\w+)(?:", "namespace",
			"(<)", "operator",
			"([^>]*)", "namespace",
			"(>?))?", "operator",
		];
		var pFull = pNew.concat(pType).concat([
			"(?:(\\s*)", cdl,
			"([:.])", "punctuation.operator",
			"(\\s*)", cdl,
			"(\\w*))?", "field"
		]);
		var pAuto = pNew.concat([
			"([:.])", "punctuation.operator",
			"(\\w*)", "field",
		]);
		var pExtends = pType.concat([
			"(\\s*)", cdl,
			"(extends|implements)", "keyword",
			"(\\s*)", cdl,
			"(\\S*)", "namespace"
		]);
		var pCall = ["(\\s*)", cdl, "(\\()", "paren.lparen"];
		var pEOL = ["($)", cdl];
		//
		var sArgs = sBase + ".args";
		var sRest = sBase + ".rest";
		out[sBase] = [
			rxRule("curly.paren.lparen", ~/\{$/, "pop"),
			rxPush("curly.paren.lparen", ~/\{/, "gml.comment.doc.curly"),
			
			rawRulePairs(pExtends.concat(pEOL), "pop"),
			rawRulePairs(pExtends, sRest),
			
			rawRulePairs(pFull.concat(pCall), sArgs),
			rawRulePairs(pFull.concat(pEOL), "pop"),
			rawRulePairs(pFull, sRest),
			
			rawRulePairs(pAuto.concat(pCall), sArgs),
			rawRulePairs(pAuto.concat(pEOL), "pop"),
			rawRulePairs(pAuto, sRest),
			
			//rawRulePairs(pNew.concat(pCall), sArgs), // `@hint new(args)` or `@hint (args)` - no use?
			rxRule(cdl, ~/$/, "pop"),
			rdef(cdl),
		];
		
		//
		var pArgClose = [
			"(\\))(?:", "paren.rparen",
			"(->)(?:", "operator",
			"(\\S+))?)?", "namespace", // I'm not going to cram a balanced <> tokenizer in here
		];
		out[sArgs] = [
			rawRulePairs(pArgClose.concat(pEOL), "pop"),
			rawRulePairs(pArgClose, sRest),
			rxRule("local", ~/\w+/),
			rxRule("punctuation.operator", ~/,/),
			rxRule(cdl, ~/$/, "pop"),
			rdef(cdl),
		];
		out[sRest] = rComment.concat([
			rxRule(cdl, ~/$/, "pop"),
			rdef(cdl),
		]);
	}
}