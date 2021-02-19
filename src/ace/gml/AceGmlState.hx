package ace.gml;
import ace.extern.AceLangRule;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class AceGmlState {
	public var state:String;
	public var depth:Int;
	
	public function new(state:String, depth:Int) {
		this.state = state;
		this.depth = depth;
	}
	public static function changeState(state:AceLangRuleState, newState:String):AceLangRuleState {
		if (Std.is(state, AceGmlState)) {
			return new AceGmlState(newState, (state:AceGmlState).depth);
		} else return newState;
	}
	public static function adjustDepth(state:AceLangRuleState, delta:Int):AceGmlState {
		if (Std.is(state, AceGmlState)) {
			return new AceGmlState((state:AceGmlState).state, (state:AceGmlState).depth + delta);
		} else {
			return new AceGmlState(state, delta);
		}
	}
	
	public function equalsTo(q:AceLangRuleState) {
		if (Std.is(q, AceGmlState)) {
			return state == (q:AceGmlState).state && depth == (q:AceGmlState).depth;
		} else return state == (q:String) && depth == 0;
	}
	public function toString() {
		return state;
	}
	
	public static function getDepth(state:AceLangRuleState):Int {
		if (Std.is(state, AceGmlState)) {
			return (state:AceGmlState).depth;
		} else return 0;
	}
	public static function getChangeState(newState:String):AceLangRuleNext {
		return function(currentState:AceLangRuleState, stack:Array<AceLangRuleState>) {
			return changeState(currentState, newState);
		}
	}
	public static function getPushState(newState:String):AceLangRuleNext {
		return function(currentState:AceLangRuleState, stack:Array<AceLangRuleState>) {
			var nextState = changeState(currentState, newState);
			if (currentState != "start" || stack.length > 0) {
				stack.unshift(currentState);
				stack.unshift(nextState);
			}
			return nextState;
		}
	}
	
	public static function tokenizerEquals(e0:TokenizerEqualsArg, e1:TokenizerEqualsArg):Bool {
		inline function equals(s0:AceLangRuleState, s1:AceLangRuleState):Bool {
			if (Std.is(s0, AceGmlState)) {
				return (s0:AceGmlState).equalsTo(s1);
			} else if (Std.is(s1, AceGmlState)) {
				return (s1:AceGmlState).equalsTo(s0);
			} else return s0 == s1;
		}
		if (Std.is(e0, Array)) {
			if (!Std.is(e1, Array)) return false;
			var a0 = (e0:Array<AceLangRuleState>);
			var a1 = (e1:Array<AceLangRuleState>);
			if (a0.length != a1.length) return false;
			for (i => s0 in a0) {
				if (!equals(s0, a1[i])) return false;
			}
			return true;
		} else {
			if (e0 == null) return e1 == null;
			if (Std.is(e1, Array)) return false;
			return equals(e0, e1);
		}
	}
}
typedef TokenizerEqualsArg = EitherType<Array<AceLangRuleState>, AceLangRuleState>;