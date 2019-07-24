package ace.extern;
import haxe.extern.EitherType;
import js.RegExp;

/**
 * ...
 * @author YellowAfterlife
 */
typedef AceLangRule = {
	?token: EitherType<EitherType<String, Array<String>>, String->String>,
	regex:EitherType<String, RegExp>,
	?onMatch:haxe.Constraints.Function,
	?next:EitherType<String, AceLangRuleNext>,
	?nextState: String,
	?push:EitherType<String, Array<AceLangRule>>,
	?consumeLineEnd:Bool,
};
typedef AceLangRuleNext = (currentState:String, stack:Array<String>)->String;
