package gml.funcdoc;
import gml.GmlFuncDoc;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTools;
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
	static var parse_rxTemplate = new RegExp("^(.*)" + "<(.+?)>\\(");
	
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
				var mt = parse_rxTemplate.exec(pre);
				if (mt != null) {
					name = mt[1];
					templateItems = [];
					for (ts in mt[2].splitRx(JsTools.rx(~/[,;]\s*/g))) {
						mt = JsTools.rx(~/^\s*(.+?)\s*:\s*(.+?)\s*$/).exec(ts);
						if (mt != null) {
							templateItems.push(new GmlTypeTemplateItem(mt[1], mt[2]));
						} else templateItems.push(new GmlTypeTemplateItem(ts.trimBoth()));
					}
				}
			}
			var sw = s.substring(p0 + 1, p1).trimBoth();
			post = s.substring(p1);
			if (sw != "") {
				args = sw.splitRx(JsTools.rx(~/,\s*/g));
				var rxt = JsTools.rx(~/:([^=]+)/);
				for (i => a in args) {
					var mt = rxt.exec(a);
					if (mt != null) {
						if (argTypes == null) argTypes = NativeArray.create(args.length);
						var typeStr = mt[1].trimRight();
						if (templateItems != null) {
							typeStr = GmlTypeTools.patchTemplateItems(typeStr, templateItems);
						}
						argTypes[i] = GmlTypeDef.parse(typeStr);
					}
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