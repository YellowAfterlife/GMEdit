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
 * Fills up a GmlFuncDoc from inputs like "func(a, b:number) does stuff"
 * @author YellowAfterlife
 */
class GmlFuncDocParser {
	static var rxTemplate = new RegExp("^(.*)" + "<(.+?)>\\(");
	public static var rxArgType = new RegExp("(?:" + [
		"/\\*:" + "(.+?)" + "\\*/", // type in a comment (as with GmlSeeker)
		":([^=]+)", // pretty `:type` (as with @hint)
	].join("|") + ")");
	
	public static function parse(str:String, ?out:GmlFuncDoc):GmlFuncDoc {
		str = GmlFuncDoc.patchArrow(str);
		var name = str;
		var pre = str;
		var post = "";
		var args = [];
		var rest = false;
		var argTypes:Array<GmlType> = null;
		var templateItems:Array<GmlTypeTemplateItem> = null;
		var parOpenAt = str.indexOf("(");
		var hasReturn:Bool = null;
		if (parOpenAt >= 0) {
			pre = str.substring(0, parOpenAt + 1);
			name = str.substring(0, parOpenAt); { // parse func<T>:
				var mt = rxTemplate.exec(pre);
				if (mt != null) {
					name = mt[1];
					templateItems = GmlTypeTemplateItem.parseSplit(mt[2]);
				}
			}
			//
			var depth = 1;
			var pos = parOpenAt + 1;
			var len = str.length;
			var argStart = pos;
			var argSpace = true;
			inline function flushArg() {
				args.push(str.substring(argStart, pos - 1));
			}
			while (pos < len) {
				var c = str.fastCodeAt(pos++);
				if (pos == argStart) {
					if (c.isSpace0()) argStart++;
				}
				switch (c) {
					case "[".code, "(".code, "{".code: depth++;
					case "]".code, ")".code, "}".code:
						if (--depth <= 0) {
							if (args.length > 0 || pos - 1 > argStart) flushArg();
							if (str.charAt(pos) == GmlFuncDoc.retArrow) {
								hasReturn = str.substr(pos + 1, 4) != "void"
									|| str.fastCodeAt(pos + 5).isIdent1_ni();
							}
							post = str.substring(pos - 1);
							break;
						}
					case ",".code if (depth == 1):
						flushArg();
						argStart = pos;
						argSpace = true;
					case ".".code:
						if (!rest
							&& str.fastCodeAt(pos) == ".".code
							&& str.fastCodeAt(pos + 1) == ".".code
						) rest = true;
				}
			}
			//
			var rxt = rxArgType;
			var showArgTypes = Preferences.current.showArgTypesInStatusBar;
			for (i => arg in args) {
				var hadBrackets = !showArgTypes && arg.startsWith("[") && arg.endsWith("]");
				if (hadBrackets) arg = arg.substring(1, arg.length - 1);
				arg = arg.replaceExt(rxt, function(argStr, t1, t2) {
					var typeStr = JsTools.or(t1, t2).trimRight();
					if (templateItems != null) {
						typeStr = GmlTypeTools.patchTemplateItems(typeStr, templateItems);
					}
					if (argTypes == null) argTypes = NativeArray.create(args.length);
					argTypes[i] = GmlTypeDef.parse(typeStr, str);
					return showArgTypes ? argStr : "";
				});
				if (hadBrackets) arg = "[" + arg + "]";
				args[i] = arg;
			}
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
		out.hasReturn = hasReturn;
		return out;
	}
}