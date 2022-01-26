package yy;
using tools.NativeString;

/**
 * Didn't think this one through
 * @author YellowAfterlife
 */
class YyTools {
	public static inline function isV22(q:YyBase):Bool {
		return q.modelName != null;
	}
	/** "GMIncludedFile" -> "includedFile" */
	public static function trimResourceType(type:String):String {
		return type.charAt(2).toLowerCase() + type.fastSubStart(3);
	}
}
