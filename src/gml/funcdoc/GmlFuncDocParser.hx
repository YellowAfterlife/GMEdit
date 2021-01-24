package gml.funcdoc;
import gml.GmlFuncDoc;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTools;
import gml.type.GmlTypeTemplateItem;
import js.lib.RegExp;
import parsers.GmlReader;
import tools.CharCode;
import tools.JsTools;
import tools.NativeArray;
import tools.RegExpCache;
import tools.Aliases;
import ui.Preferences;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFuncDocParser {
	static var rxTemplate = new RegExp("^(.*)" + "<(.+?)>\\(");
	public static var rxArgType = new RegExp("(?:" + [
		"/\\*:" + "(.+?)" + "\\*/", // type in a comment (as with GmlSeeker)
		":([^=]+)", // pretty `:type` (as with @hint)
	].join("|") + ")");
	
	public static function parse(s:String, ?out:GmlFuncDoc):GmlFuncDoc {
		s = GmlFuncDoc.patchArrow(s);
		var parOpenAt = s.indexOf("(");
		var parCloseAt = s.indexOf(")", parOpenAt);
		var name:String, pre:String, post:String, args:Array<String>, rest:Bool;
		var argTypes:Array<GmlType> = null;
		var templateItems:Array<GmlTypeTemplateItem> = null;
		if (parOpenAt >= 0 && parCloseAt >= 0) {
			pre = s.substring(0, parOpenAt + 1);
			name = s.substring(0, parOpenAt); {
				var mt = rxTemplate.exec(pre);
				if (mt != null) {
					name = mt[1];
					templateItems = GmlTypeTemplateItem.parseSplit(mt[2]);
				}
			}
			var sw = s.substring(parOpenAt + 1, parCloseAt).trimBoth();
			post = s.substring(parCloseAt);
			if (sw != "") {
				args = sw.splitRx(JsTools.rx(~/,\s*/g));
				var rxt = rxArgType;
				var showArgTypes = Preferences.current.showArgTypesInStatusBar;
				for (i in 0 ... args.length) {
					var arg = args[i];
					var hadBrackets = !showArgTypes && arg.startsWith("[") && arg.endsWith("]");
					if (hadBrackets) arg = arg.substring(1, arg.length - 1);
					arg = arg.replaceExt(rxt, function(str, t1, t2) {
						var typeStr = JsTools.or(t1, t2).trimRight();
						if (templateItems != null) {
							typeStr = GmlTypeTools.patchTemplateItems(typeStr, templateItems);
						}
						if (argTypes == null) argTypes = NativeArray.create(args.length);
						argTypes[i] = GmlTypeDef.parse(typeStr);
						return showArgTypes ? str : "";
					});
					if (hadBrackets) arg = "[" + arg + "]";
					args[i] = arg;
				}
			} else args = [];
			rest = sw.contains("...");
		} else {
			name = s;
			pre = s;
			post = "";
			args = [];
			rest = false;
		}
		if (out != null) {
			@:privateAccess out.minArgsCache = null;
			out.name = name;
			out.pre = pre;
			out.post = post;
			out.args = args;
			out.rest = rest;
		} else {
			out = new GmlFuncDoc(name, pre, post, args, rest);
		}
		out.argTypes = argTypes;
		out.templateItems = templateItems;
		return out;
	}
}