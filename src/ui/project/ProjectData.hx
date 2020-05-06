package ui.project;
import tools.Aliases;

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
	
	/** "windows", "unix", null */
	?newLineMode:String,
	
	?lambdaMode:LambdaMode,
	
	?argNameRegex:String,
	
	?templateStringScript:GmlName,
	
	?linterPrefs:parsers.linter.GmlLinterPrefs,
}
enum abstract LambdaMode(Int) from Int to Int {
	/// may also be null
	var Default = 0;
	var Macros = 1;
	var Scripts = 2;
}
