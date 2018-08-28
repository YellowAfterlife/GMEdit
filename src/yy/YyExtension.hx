package yy;

/**
 * A very partial typedef
 * @author YellowAfterlife
 */
typedef YyExtension = {
	>YyBase,
	name:String,
	files:Array<YyExtensionFile>,
}
typedef YyExtensionFile = {
	>YyBase,
	filename:String,
	functions:Array<YyExtensionFunc>,
	constants:Array<YyExtensionMacro>,
	order:Array<YyGUID>,
}
typedef YyExtensionFunc = {
	>YyBase,
	name:String,
	externalName:String,
	help:String,
	args:Array<Int>,
	argCount:Int,
	hidden:Bool,
	kind:Int,
	returnType:Int,
}
typedef YyExtensionMacro = {
	>YyBase,
	constantName:String,
	hidden:Bool,
	value:String,
}
