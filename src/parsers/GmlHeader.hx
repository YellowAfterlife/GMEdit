package parsers;
import gml.GmlVersion;
import js.RegExp;

/**
 * Extracts a header label from code.
 * Format is as following:
 * /// GMS1
 * /// @desc GMS2
 * @author YellowAfterlife
 */
class GmlHeader {
	private static var rx1 = new RegExp("^///(.*)(?:\r?\n|$)");
	private static var rx2 = new RegExp("^///[ \t]*@desc(?:ription)?([ \t]+.*)(?:\r?\n|$)");
	public static function parse(code:String, version:GmlVersion):GmlHeaderData {
		var jsdoc = version.hasJSDoc();
		var rx = jsdoc ? rx2 : rx1;
		var mt = rx.exec(code);
		var name:String = null;
		if (mt != null) {
			var name = mt[1];
			if (name.charCodeAt(0) != " ".code) name = "|" + name;
			return { name: name, code: code.substring(mt[0].length) };
		} else return { name: null, code: code };
	}
}
typedef GmlHeaderData = { name:String, code:String };
