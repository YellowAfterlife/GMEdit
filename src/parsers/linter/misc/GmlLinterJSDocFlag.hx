package parsers.linter.misc;
import ace.extern.AceAutoCompleteItem;
import ace.extern.AceAutoCompleteItems;
import parsers.linter.GmlLinter;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLinterJSDocFlag {
	public static var comp:AceAutoCompleteItems = [];
	static function init() {
		var map:Dictionary<GmlLinterJSDocFlagFunc> = new Dictionary();
		function add(key:String, fn:GmlLinterJSDocFlagFunc, desc:String) {
			map[key] = fn;
			comp.push(new AceAutoCompleteItem(key, "variable", desc));
		}
		add("all", function(l:GmlLinter, val) {
			l.prefs.suppressAll = val == null ? false : !val;
		}, "Suppresses all non-syntax-error flags if disabled");
		add("nullToAny", function(l:GmlLinter, val) {
			gml.type.GmlTypeCanCastTo.allowNullToAny = val;
		}, "Allows casting `undefined` to anything");
		return map;
	}
	public static var map:Dictionary<GmlLinterJSDocFlagFunc> = init();
}
typedef GmlLinterJSDocFlagFunc = (linter:GmlLinter, val:Bool)->Void;
