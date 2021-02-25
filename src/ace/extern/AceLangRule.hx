package ace.extern;
import haxe.Constraints.Function;
import haxe.extern.EitherType;
import js.lib.RegExp;
import tools.Aliases;

/**
 * ...
 * @author YellowAfterlife
 */
typedef AceLangRule = {
	?token:AceLangRuleTokenInit,
	?regex:EitherType<String, RegExp>,
	?onMatch:AceLangRuleMatch,
	?next:AceLangRuleNextInit,
	?nextState: AceLangRuleState,
	?push:AceLangRuleNextInit,
	?consumeLineEnd:Bool,
	?splitRegex:RegExp,
};
/**
 * Function option here will be called with one argument per match group,
 * which makes it not very constraint-able.
 */
typedef AceLangRuleTokenInit = EitherType3<AceTokenType, Array<AceTokenType>, Function>;
typedef AceLangRuleState = EitherType<String, ace.gml.AceGmlState>;
typedef AceLangRuleMatch = EitherType<
	(value:String, currentState:AceLangRuleState, stack:Array<String>, line:String, row:Int)->AceTokenType,
	(value:String, currentState:AceLangRuleState, stack:Array<String>, line:String, row:Int)->Array<AceToken>
>;

/**
push: "name" and next: "pop" rule fields work like this:
```
var pushState = function(currentState, stack) {
	if (currentState != "start" || stack.length)
		stack.unshift(this.nextState, currentState);
	return this.nextState;
};
var popState = function(currentState, stack) {
	stack.shift();
	return stack.shift() || "start";
};
```
So, the top-level state is "start";
When you push a state over it, it replaces the state, but doesn't push to the stack;
When you push *another* state, it pushes the original state and itself to the stack;
Popping a state discards the new state name and uses the original state,
or uses "start" once the stack has been emptied.

state: "start", stack: []
push:"one" -> state: "one", stack: []
push:"two" -> state: "two", stack: ["two", "one"]
next:"pop" -> state: "one", stack: []
next:"pop" -> state: "start", stack: []
**/
typedef AceLangRuleNext = (currentState:AceLangRuleState, stack:Array<AceLangRuleState>)->AceLangRuleState;
typedef AceLangRuleNextInit = EitherType3<AceLangRuleState, Array<AceLangRuleState>, AceLangRuleNext>;
