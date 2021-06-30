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

@:forward
abstract YyExtensionFile(YyExtensionFileImpl) from YyExtensionFileImpl to YyExtensionFileImpl {
	public var finalizer(get, set):String;
	private inline function get_finalizer():String {
		return Reflect.field(this, "final");
	}
	private inline function set_finalizer(val:String):String {
		Reflect.setField(this, "final", val);
		return val;
	}
}
typedef YyExtensionFileImpl = {
	>YyBase,
	filename:String,
	origname:String,
	functions:Array<YyExtensionFunc>,
	constants:Array<YyExtensionMacro>,
	order:Array<YyGUID>,
	init:String,
	uncompress:Bool,
	copyToTargets:Dynamic,
	ProxyFiles:Array<Any>,
	kind:YyExtensionFileKind,
	?name:String,
}
enum abstract YyExtensionFileKind(Int) {
	var Native = 1;
	var GML = 2;
	public static function detect(path:String):YyExtensionFileKind {
		return switch (haxe.io.Path.extension(path).toLowerCase()) {
			case "gml": GML;
			default: Native;
		}
	}
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
