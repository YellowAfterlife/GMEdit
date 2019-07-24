package parsers;

import gml.GmlVersion;

/**
 * Like GmlReader, but supports stacking states for macro parsing
 * @author YellowAfterlife
 */
class GmlReaderExt extends GmlReader {
	var oldSource:Array<String> = [];
	var oldPos:Array<Int> = [];
	var oldLength:Array<Int> = [];
	public var depth(get, never):Int;
	private inline function get_depth():Int {
		return oldSource.length;
	}
	//
	override function get_loop():Bool {
		if (pos < length) return true;
		while (oldSource.length > 0) {
			source = oldSource.pop();
			pos = oldPos.pop();
			length = oldLength.pop();
			if (pos < length) return true;
		}
		return false;
	}
	override function get_eof():Bool {
		return !get_loop();
	}
	//
	public function pushSource(code:String) {
		oldSource.push(source);
		oldPos.push(pos);
		oldLength.push(length);
		//
		source = code;
		pos = 0;
		length = code.length;
	}
}
