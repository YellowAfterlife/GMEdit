package gml;
import electron.FileWrap;
import gmx.SfGmx;
import yy.YyExtension;
import gml.file.GmlFile;
import file.FileKind;
import file.kind.gmx.KGmxExtensionAPI;
import file.kind.yy.KYyExtensionAPI;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtensionAPI {
	public static function showFor(path:String, ident:String) {
		var kind = switch (Project.current.version) {
			case v1: KGmxExtensionAPI.inst;
			case v2: KYyExtensionAPI.inst;
			default: return;
		}
		GmlFile.openTab(new GmlFile("api: " + ident, path, kind));
	}
	//
	static function procFn(name:String, help:String, argc:Int, hidden:Bool):String {
		var r = help;
		if (r == "") {
			r = name + "(";
			if (argc >= 0) for (i in 0 ... argc) {
				if (i > 0) r += ", ";
				r += "v" + i;
			} else r += "...";
			r += ")";
		}
		if (hidden) r += " // hidden";
		return r;
	}
	static function procMc(name:String, val:String, hidden:Bool):String {
		var r = '$name = $val';
		if (hidden) r += " // hidden";
		return r;
	}
	static function procSort(a:String, b:String) {
		return untyped (a < b ? -1 : a > b ? 1 : 0);
	}
	//
	public static function get1(src:String):String {
		var ext = SfGmx.parse(src);
		var out = "";
		for (file in ext.find("files").findAll("file")) {
			if (out != "") out += "\n";
			out += "#section " + file.findText("filename");
			var lines = [], s:String;
			for (fn in file.find("functions").findAll("function")) {
				lines.push(procFn(
					fn.findText("name"),
					fn.findText("help"),
					fn.findInt("argCount"),
					fn.findText("kind") == "11")
				);
			}
			for (mc in file.find("constants").findAll("constant")) {
				lines.push(procMc(mc.findText("name"), mc.findText("value"), mc.findInt("hidden") != 0));
			}
			lines.sort(procSort);
			for (line in lines) out += "\n" + line;
		}
		return out;
	}
	public static function get2(ext:YyExtension):String {
		var out = "";
		for (file in ext.files) {
			if (out != "") out += "\n";
			out += "#section " + file.filename;
			var lines = [], s:String;
			for (fn in file.functions) lines.push(procFn(fn.name, fn.help, fn.argCount, fn.hidden));
			for (mc in file.constants) lines.push(procMc(mc.constantName, mc.value, mc.hidden));
			lines.sort(procSort);
			for (line in lines) out += "\n" + line;
		}
		return out;
	}
}
