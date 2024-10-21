package yy;
#if js
import js.lib.RegExp;
#end

/**
 * ...
 * @author YellowAfterlife
 */
abstract YyGUID(String) to String {
	/** 2.2 */
	public static inline var zero:YyGUID = cast "00000000-0000-0000-0000-000000000000";
	/** 2.3 */
	public static inline var blank:YyGUID = cast "";
	
	public static inline function getDefault(v22:Bool) {
		return v22 ? zero : blank;
	}
	
	#if js
	public static var test:RegExp = {
		var h = '[0-9a-fA-F]';
		new RegExp('^$h{8}-$h{4}-$h{4}-$h{4}-$h{12}' + "$");
	};
	#else
	public static var test:EReg = {
		var h = '[0-9a-fA-F]';
		new EReg('^$h{8}-$h{4}-$h{4}-$h{4}-$h{12}' + "$", "");
	};
	#end
	static function create() {
		var result = "";
		for (j in 0 ... 32) {
			if (j == 8 || j == 12 || j == 16 || j == 20) {
				result += "-";
			}
			if (j == 12) {
				result += "4";
			}
			else if (j == 16) {
				result += "89ab".charAt(Std.random(4));
			}
			else {
				result += "0123456789abcdef".charAt(Std.random(16));
			}
		}
		return result;
	}
	#if js
	public static function createNum(count:Int, ?pj:YyProject):Array<YyGUID> {
		var out = [];
		var taken = new Map();
		if (pj != null) for (pair in pj.resources) {
			taken.set(pair.Key, true);
			taken.set(pair.Value.id, true);
		}
		for (i in 0 ... count) {
			var id:YyGUID;
			do {
				id = new YyGUID();
			} while (taken.exists(id));
			out.push(id);
		}
		return out;
	}
	#end
	public inline function new() {
		this = create();
	}
	public function isBlank():Bool {
		return this == null || this == "" || this == zero;
	}
	public function isValid():Bool {
		return this != null && this != "" && this != zero;
	}
	public inline function toString() {
		return this;
	}
}
