package ui.project;

/**
 * ...
 * @author YellowAfterlife
 */
typedef ProjectData = {
	/** API override */
	?gmlVersion:String,
	
	/** [in spaces] */
	?indentSize:Int,
	?indentWithTabs:Bool,
	?lambdaMode:LambdaMode,
	?argNameRegex:String,
	?linterPrefs:parsers.linter.GmlLinterPrefs,
}
enum abstract LambdaMode(Int) from Int to Int {
	/// may also be null
	var Default = 0;
	var Macros = 1;
	var Scripts = 2;
}
