package tools;

/**
 * ...
 * @author YellowAfterlife
 */
abstract CharCode(Int) from Int to Int {
	/** Returns whether this is a space or a tab character */
	public inline function isSpace0() {
		return (this == " ".code || this == "\t".code);
	}
	/** Returns whether this is a space/tab/newline character */
	public inline function isSpace1() {
		return (this > 8 && this < 14) || this == 32;
	}
	/** Returns whether this is a valid first character for an identifier */
	public inline function isIdent0() {
		return (this == "_".code
			|| (this >= "a".code && this <= "z".code)
			|| (this >= "A".code && this <= "Z".code)
		);
	}
	/** Returns whether this is a valid character for an identifier */
	public inline function isIdent1() {
		return (this == "_".code
			|| (this >= "a".code && this <= "z".code)
			|| (this >= "A".code && this <= "Z".code)
			|| (this >= "0".code && this <= "9".code)
		);
	}
}
