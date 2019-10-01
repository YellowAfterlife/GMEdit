package ace.extern;
import haxe.extern.EitherType;
import js.lib.RegExp;

/**
 * ...
 * @author YellowAfterlife
 */
typedef AceLangRule = {
	?token: EitherType<EitherType<String, Array<String>>, String->String>,
	regex:EitherType<String, RegExp>,
	?onMatch:AceLangRuleMatch,
	?next:EitherType<String, AceLangRuleNext>,
	?nextState: String,
	?push:EitherType<String, Array<AceLangRule>>,
	?consumeLineEnd:Bool,
	?splitRegex:RegExp,
};
typedef AceLangRuleMatch = (value:String, currentState:String, stack:Array<String>, line:String, row:Int)->EitherType<String, Array<AceToken>>;
typedef AceLangRuleNext = (currentState:String, stack:Array<String>)->String;
