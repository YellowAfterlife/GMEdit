package gml;
import electron.FileWrap;
import yy.YyExtension;
import gml.file.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtensionAPI {
	public static function showFor(path:String, ident:String) {
		GmlFile.openTab(new GmlFile(
			"api: " + ident, path,
			gml.file.GmlFileKind.YyExtensionAPI
		));
	}
	public static function get2(ext:YyExtension):String {
		var out = "";
		for (file in ext.files) {
			out += "#section " + file.filename;
			var lines = [], s:String;
			for (fn in file.functions) {
				s = (fn.help != "" ? fn.help : fn.name);
				if (fn.hidden) s += "~";
				lines.push(s);
			}
			for (mc in file.constants) {
				s = mc.constantName + " = " + mc.value;
				if (mc.hidden) s += "~";
				lines.push(s);
			}
			lines.sort((a:Dynamic, b:Dynamic) -> (a < b ? -1 : a > b ? 1 : 0));
			for (line in lines) out += "\n" + line;
		}
		return out;
	}
}
