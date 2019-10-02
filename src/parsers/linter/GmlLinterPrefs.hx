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
		requireFunctions: true,
	};
}
typedef GmlLinterPrefsImpl = {
	?onLoad:Bool,
	?onSave:Bool,
	?requireSemicolons:Bool,
	?requireParentheses:Bool,
	?noSingleEquals:Bool,
	?blockScopedVar:Bool,
	?requireFunctions:Bool,
}
