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
			var project = Project.current;
			var version = project != null ? project.version : GmlVersion.v2;
			var q = new GmlReader(str, version);
			q.pos = parOpenAt + 1;
			var argStart = q.pos;
			var argSpace = true;
			inline function flushArg() {
				args.push(q.substring(argStart, q.pos - 1).trimBoth());
			}
			while (q.loop) {
				var c = q.read();
				if (q.pos == argStart) {
					if (c.isSpace0()) argStart++;
				}
				switch (c) {
					case "[".code, "(".code, "{".code: depth++;
					case "]".code, ")".code, "}".code:
						if (--depth <= 0) {
							if (args.length > 0 || q.pos - 1 > argStart) flushArg();
							if (q.peekstr(1) == GmlFuncDoc.retArrow) {
								hasReturn = q.peekstr(4, 1) != "void"
									|| q.peek(5).isIdent1_ni();
							}
							post = str.substring(q.pos - 1);
							break;
						}
					case '"'.code, "'".code, "@".code, "`".code: q.skipStringAuto(c, version);
					case ",".code if (depth == 1):
						flushArg();
						argStart = q.pos;
						argSpace = true;
					case ".".code:
						if (!rest
							&& q.peek(0) == ".".code
							&& q.peek(1) == ".".code
						) {
							rest = true;
							q.skip(2);
						}
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