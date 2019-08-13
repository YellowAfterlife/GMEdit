package gml;
import electron.FileWrap;
import gmx.SfGmx;
import yy.YyExtension;
import gml.file.GmlFile;
import file.FileKind;
import file.kind.gmx.KGmxExtensionAPI;
import file.kind.yy.KYyExtensionAPI;
using tools.NativeString;

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
	static function procFn(name:String, exname:String, help:String, argc:Int, hidden:Bool):String {
		var r = help;
		if (r == "") {
			r = name + "(";
			if (argc >= 0) for (i in 0 ... argc) {
				if (i > 0) r += ", ";
				r += "v" + i;
			} else r += "...";
			r += ")";
		} else {
			var p = r.indexOf(")");
			if (p >= 0 && ++p < r.length) {
				var rest = r.substring(p).trimLeft();
				if (rest.charAt(0) == ":" && StringTools.isSpace(rest, 1)) {
					// `func() : desc` -> `func() // desc`
					rest = rest.substring(2);
				}
				if (rest.startsWith("//")) {
					// `// desc` -> `desc`
					rest = rest.substring(2).trimLeft();
				}
				r = r.substring(0, p) + " // " + rest;
			}
		}
		//if (hidden) r += " // hidden";
		if (exname != name) r += "\n// external: " + exname;
		return r;
	}
	static function procMc(name:String, val:String, hidden:Bool):String {
		var r = '$name = $val';
		//if (hidden) r += " // hidden";
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
			var linesShow = [], linesHide = [];
			for (fn in file.find("functions").findAll("function")) {
				var hidden = fn.findText("help") == "";
				(hidden ? linesHide : linesShow).push(procFn(
					fn.findText("name"),
					fn.findText("externalName"),
					fn.findText("help"),
					fn.findInt("argCount"),
					hidden
				));
			}
			for (mc in file.find("constants").findAll("constant")) {
				var hidden = mc.findInt("hidden") != 0;
				(hidden ? linesHide : linesShow).push(procMc(
					mc.findText("name"),
					mc.findText("value"),
					hidden
				));
			}
			//
			linesShow.sort(procSort);
			if (out != "") out += "\n";
			out += "#section " + file.findText("filename");
			for (line in linesShow) out += "\n" + line;
			//
			if (linesHide.length > 0) {
				linesHide.sort(procSort);
				out += "\n#section " + file.findText("filename") + " (hidden)";
				for (line in linesHide) out += "\n" + line;
			}
		}
		return out;
	}
	public static function get2(ext:YyExtension):String {
		var out = "";
		for (file in ext.files) {
			var linesShow = [], linesHide = [];
			for (fn in file.functions) {
				(fn.hidden ? linesHide : linesShow).push(procFn(
					fn.name, fn.externalName, fn.help, fn.argCount, fn.hidden));
			}
			for (mc in file.constants) {
				(mc.hidden ? linesHide : linesShow).push(procMc(
					mc.constantName, mc.value, mc.hidden));
			}
			//
			linesShow.sort(procSort);
			if (out != "") out += "\n";
			out += "#section " + file.filename;
			for (line in linesShow) out += "\n" + line;
			//
			if (linesHide.length > 0) {
				linesHide.sort(procSort);
				out += "\n#section " + file.filename + " (hidden)";
				for (line in linesHide) out += "\n" + line;
			}
		}
		return out;
	}
}
