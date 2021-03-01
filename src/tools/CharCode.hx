package tools;

/**
 * Helpers for checking character code ranges.
 * @author YellowAfterlife
 */
abstract CharCode(Int) from Int to Int {
	
	public static inline function at(s:String, index:Int):CharCode {
		return StringTools.fastCodeAt(s, index);
	}
	
	public var code(get, never):Int;
	private inline function get_code():Int return this;
	
	/** Returns whether this is a space or a tab character */
	public inline function isSpace0() {
		return (this == " ".code || this == "\t".code);
	}
	
	/** Returns whether this is a space/tab/newline character */
	public inline function isSpace1() {
		return (this > 8 && this < 14) || this == 32;
	}
	public function isSpace1_ni() return isSpace1();
	
	/** Returns whether this is a valid first character for an identifier */
	public inline function isIdent0() {
		return (this == "_".code
			|| (this >= "a".code && this <= "z".code)
			|| (this >= "A".code && this <= "Z".code)
		);
	}
	public function isIdent0_ni() return isIdent0();
	
	/** Returns whether this is a valid character for an identifier */
	public inline function isIdent1() {
		return (this == "_".code
			|| (this >= "a".code && this <= "z".code)
			|| (this >= "A".code && this <= "Z".code)
			|| (this >= "0".code && this <= "9".code)
		);
	}
	public function isIdent1_ni() return isIdent1();
	
	//
	public inline function isDigit() {
		return (this >= "0".code && this <= "9".code);
	}
	public function isHex() {
		return((this >= "0".code && this <= "9".code)
			|| (this >= "a".code && this <= "f".code)
			|| (this >= "A".code && this <= "F".code)
		);
	}
}
