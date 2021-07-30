package parsers.linter;

/**
 * ...
 * @author ...
 */
@:forward abstract GmlLinterPrefs(GmlLinterPrefsImpl) from GmlLinterPrefsImpl to GmlLinterPrefsImpl {
	public static var defValue:GmlLinterPrefs = {
		onLoad: true,
		onSave: true,
		requireSemicolons: false,
		requireParentheses: false,
		noSingleEquals: false,
		blockScopedVar: false,
		blockScopedCase: false,
		requireFunctions: true,
		checkHasReturn: true,
		checkScriptArgumentCounts: true,
		specTypeVar: false,
		specTypeLet: false,
		specTypeConst: false,
		specTypeMisc: false,
		specTypeInst: false,
		requireFields: false,
		implicitNullableCasts: false,
		implicitBoolIntCasts: true,
		
		liveCheckOnEnter: false,
		liveCheckOnSemico: false,
		liveMaxLines: 100,
		liveMinDelay: 250,
		
		liveIdleDelay: 0,
		liveIdleMaxLines: 300,
	};
}
typedef GmlLinterPrefsImpl = {
	?onLoad:Bool,
	?onSave:Bool,
	?requireSemicolons:Bool,
	?requireParentheses:Bool,
	?noSingleEquals:Bool,
	?blockScopedVar:Bool,
	?blockScopedCase:Bool,
	?requireFunctions:Bool,
	?checkHasReturn:Bool,
	?checkScriptArgumentCounts:Bool,
	?specTypeVar:Bool,
	?specTypeLet:Bool,
	?specTypeConst:Bool,
	?specTypeMisc:Bool,
	?specTypeInst:Bool,
	?requireFields:Bool,
	
	/** Whether to allow implicit T?->T casts */
	?implicitNullableCasts:Bool,
	
	/** Whether to allow implicit bool<->int casts */
	?implicitBoolIntCasts:Bool,
	
	?liveCheckOnEnter:Bool,
	?liveCheckOnSemico:Bool,
	?liveMaxLines:Int,
	?liveMinDelay:Int,
	?liveIdleDelay:Int,
	?liveIdleMaxLines:Int,
}
