package yy;

/**
 * A very partial typedef
 * @author YellowAfterlife
 */
typedef YyExtension = {
	>YyResource,
	name:String,
	files:Array<YyExtensionFile>,
}
typedef YyExtensionFile = {
	>YyBase,
	filename:String,
	functions:Array<YyExtensionFunc>,
	constants:Array<YyExtensionMacro>,
	order:Array<YyGUID>,
	init:String,
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
	/** ≤2.2.5 */
	?constantName:String,
	/** ≥2.3 */
	?name:String,
	/** Ideally hidden from the user, but base IDE doesn't always care */
	hidden:Bool,
	/** Token-wise a more or less literal replacement */
	value:String,
}
