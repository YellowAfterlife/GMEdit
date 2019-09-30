package parsers;
import gml.GmlVersion;
import js.lib.RegExp;

/**
 * Extracts a header label from code.
 * Format is as following:
 * /// GMS1
 * /// @desc GMS2
 * @author YellowAfterlife
 */
class GmlHeader {
	private static var rx1 = new RegExp("^///(.*)(?:\r?\n|$)");
	private static var rx2 = new RegExp("^/// @(description|desc)?( .*)(?:\r?\n|$)");
	public static function parse(code:String, version:GmlVersion):GmlHeaderData {
		var mt:RegExpMatch, name:String = null;
		if (version.config.hasJSDoc) {
			mt = rx2.exec(code);
			if (mt != null) {
				name = mt[2];
				if (mt[1] == "desc") name = "|" + name.substring(1);
			}
		} else {
			mt = rx1.exec(code);
			if (mt != null) {
				name = mt[1];
				if (name.charCodeAt(0) != " ".code) name = "|" + name;
			}
		}
		if (mt != null) {
			return { name: name, code: code.substring(mt[0].length) };
		} else return { name: null, code: code };
	}
}
typedef GmlHeaderData = { name:String, code:String };
