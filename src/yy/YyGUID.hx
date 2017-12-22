package yy;

/**
 * ...
 * @author YellowAfterlife
 */
abstract YyGUID(String) to String {
	public static inline var zero:YyGUID = cast "00000000-0000-0000-0000-000000000000";
	static function create() {
		var result = "";
		for (j in 0 ... 32) {
			if (j == 8 || j == 12 || j == 16 || j == 20) {
				result += "-";
			}
			result += "0123456789ABCDEF".charAt(Math.floor(Math.random() * 16));
		}
		return result;
	}
	public inline function new() {
		this = create();
	}
	public inline function toString() {
		return this;
	}
}
