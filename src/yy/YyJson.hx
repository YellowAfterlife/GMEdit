package yy;
import haxe.Json;
import haxe.ds.ObjectMap;
import tools.Dictionary;
using tools.NativeString;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class YyJson {
	static function isExtJson(src:String):Bool {
		var p = src.length - 1;
		while (p >= 0) {
			switch (src.fastCodeAt(p)) {
				case " ".code, "\t".code, "\r".code, "\n".code: p--;
				case "}".code, "]".code: p--; break;
				default: return false;
			}
		}
		while (p >= 0) {
			switch (src.fastCodeAt(p)) {
				case " ".code, "\t".code, "\r".code, "\n".code: p--;
				case ",".code: return true;
				default: return false;
			}
		}
		return false;
	}
	public static function parse(src:String):Dynamic {
		if (isExtJson(src)) {
			return YyJsonParser.parse(src);
		} else return Json.parse(src);
	}
	public static function stringify(obj:Dynamic, extJson:Bool = false):String {
		return YyJsonPrinter.stringify(obj, extJson);
	}
}
