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
		var p0 = s.indexOf("(");
		var p1 = s.indexOf(")", p0);
		var name:String, pre:String, post:String, args:Array<String>, rest:Bool;
		var argTypes:Array<GmlType> = null;
		var templateItems:Array<GmlTypeTemplateItem> = null;
		if (p0 >= 0 && p1 >= 0) {
			pre = s.substring(0, p0 + 1);
			name = s.substring(0, p0); {
				var mt = rxTemplate.exec(pre);
				if (mt != null) {
					name = mt[1];
					templateItems = GmlTypeTemplateItem.parseSplit(mt[2]);
				}
			}
			var sw = s.substring(p0 + 1, p1).trimBoth();
			post = s.substring(p1);
			if (sw != "") {
				args = sw.splitRx(JsTools.rx(~/,\s*/g));
				var rxt = rxArgType;
				for (i in 0 ... args.length) {
					args[i] = args[i].replaceExt(rxt, function(_, t1, t2) {
						if (argTypes == null) argTypes = NativeArray.create(args.length);
						var typeStr = JsTools.or(t1, t2).trimRight();
						if (templateItems != null) {
							typeStr = GmlTypeTools.patchTemplateItems(typeStr, templateItems);
						}
						argTypes[i] = GmlTypeDef.parse(typeStr);
						return "";
					});
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