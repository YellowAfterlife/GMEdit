package ace.extern;
import ace.extern.AceTokenType;

/**
 * ...
 * @author YellowAfterlife
 */
enum AceLangRuleDef {
	Token(regex:String, type:AceTokenType);
	OptToken(regex:String, type:AceTokenType);
	OptGroup(defs:Array<AceLangRuleDef>);
}
