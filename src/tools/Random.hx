package tools;

class Random {
	/** Generates number from a random range, exclusive
	**/
	public static function range(start : Int, end : Int) : Int {
		return (Std.random(end-start)+start);
	}
	/** Generates a random bool
	**/
	public static function bool() : Bool {
		return (Std.random(2) == 0);
	}

	/**Generates a random number up to but not including size*/
	public static function integer(size: Int): Int {
		return (Std.random(size));
	}

	/** Generates a random string with characters A-Z, a-z
	 * 
	**/
	public static function letterString(length : Int) : String {
		var s = "";
		for (_ in 0...length) {
			s += String.fromCharCode(
				bool() ? range('A'.code, 'Z'.code) : range('a'.code, 'z'.code)
			);
		}
		return s;
	}
}