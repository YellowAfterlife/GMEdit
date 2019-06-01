package ui.project;

/**
 * ...
 * @author YellowAfterlife
 */
typedef ProjectData = {
	?indentSize:Int,
	?indentWithTabs:Bool,
	?lambdaMode:LambdaMode,
}
enum abstract LambdaMode(Int) from Int to Int {
	/// may also be null
	var Default = 0;
	var Macros = 1;
	var Scripts = 2;
}
