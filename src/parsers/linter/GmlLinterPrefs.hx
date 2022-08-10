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
		specTypeStatic: false,
		specTypeLet: false,
		specTypeConst: false,
		specTypeMisc: false,
		specTypeInst: false,
		specTypeColon: false,
		specTypeInstSubTopLevel: false,
		
		requireFields: false,
		implicitNullableCasts: false,
		implicitBoolIntCasts: true,
		warnAboutRedundantCasts: false,
		strictScriptSelf: false,
		
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
	
	/** auto-infer for `var` */
	?specTypeVar:Bool,
	
	/** auto-infer for `static` */
	?specTypeStatic:Bool,
	
	/** auto-infer for `let` (var macro) */
	?specTypeLet:Bool,
	
	/** auto-infer for `const` (var macro) */
	?specTypeConst:Bool,
	
	/** auto-infer for any other var macros */
	?specTypeMisc:Bool,
	
	/** auto-infer when doing := */
	?specTypeColon:Bool,
	
	/** auto-infer assignments in Create */
	?specTypeInst:Bool,
	
	/** auto-infer non-top-level assignments in Create */
	?specTypeInstSubTopLevel:Bool,
	
	/** warn about missing fields */
	?requireFields:Bool,
	
	/** Whether to allow implicit T?->T casts */
	?implicitNullableCasts:Bool,
	
	/** Whether to allow implicit bool<->int casts */
	?implicitBoolIntCasts:Bool,
	
	/** Whether to show warnings when trying to cast a type to something it already is */
	?warnAboutRedundantCasts:Bool,
	
	/** Whether to assume scripts without a @self to have {void} @self */
	?strictScriptSelf:Bool,
	
	?liveCheckOnEnter:Bool,
	?liveCheckOnSemico:Bool,
	?liveMaxLines:Int,
	?liveMinDelay:Int,
	?liveIdleDelay:Int,
	?liveIdleMaxLines:Int,
}
