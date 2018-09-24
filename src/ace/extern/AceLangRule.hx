package ace.extern;
import haxe.extern.EitherType;
import js.RegExp;

/**
 * ...
 * @author YellowAfterlife
 */
typedef AceLangRule = {
	?token: EitherType<String, String->String>,
	regex:EitherType<String, RegExp>,
	?onMatch:haxe.Constraints.Function,
	?next: String,
	?nextState: String,
	?push:EitherType<String, Array<AceLangRule>>,
};
