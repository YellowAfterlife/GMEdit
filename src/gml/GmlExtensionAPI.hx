package gml;
import electron.FileWrap;
import gmx.SfGmx;
import haxe.DynamicAccess;
import ui.Preferences;
import yy.YyExtension;
import gml.file.GmlFile;
import file.FileKind;
import file.kind.gmx.KGmxExtensionAPI;
import file.kind.yy.KYyExtensionAPI;
import tools.JsTools.or;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtensionAPI {
	public static var kindMap:DynamicAccess<FileKind> = {
		"gms1": KGmxExtensionAPI.inst,
		"gms2": KYyExtensionAPI.inst,
	}
	public static function showFor(path:String, ident:String) {
		var kind = kindMap[Project.current.version.config.projectMode];
		if (kind == null) return;
		GmlFile.openTab(new GmlFile("api: " + ident, path, kind));
	}
	//
	static function procFn(name:String, exname:String, help:String, args:Array<String>, hidden:Bool):String {
		var r = help;
		if (r == "") {
			r = name + "(";
			var sep = false;
			for (arg in args) {
				if (sep) r += ", "; else sep = true;
				r += arg;
			}
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
	static function procSortAuto(lines:Array<String>) {
		if (Preferences.current.extensionAPIOrder == 1) {
			lines.sort(procSort);
		}
	}
	//
	public static function get1(src:String):String {
		var ext = SfGmx.parse(src);
		var out = "";
		for (file in ext.find("files").findAll("file")) {
			var linesShow = [], linesHide = [];
			for (fn in file.find("functions").findAll("function")) {
				var hidden = fn.findText("help") == "";
				var argc = fn.findInt("argCount");
				var args:Array<String> = [];
				if (argc < 0) {
					args.push("...");
				} else for (arg in fn.find("args").findAll("arg")) {
					args.push((arg.text == "1" ? "s" : "v") + args.length);
				}
				(hidden ? linesHide : linesShow).push(procFn(
					fn.findText("name"),
					fn.findText("externalName"),
					fn.findText("help"),
					args,
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
			procSortAuto(linesShow);
			if (out != "") out += "\n";
			out += "#section " + file.findText("filename");
			for (line in linesShow) out += "\n" + line;
			//
			if (linesHide.length > 0) {
				procSortAuto(linesHide);
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
				var args = [];
				if (fn.argCount < 0) {
					args.push("...");
				} else for (arg in fn.args) {
					args.push((arg == 1 ? "s" : "v") + args.length);
				}
				(fn.hidden ? linesHide : linesShow).push(procFn(
					fn.name, fn.externalName, fn.help, args, fn.hidden));
			}
			for (mc in file.constants) {
				var name = or(mc.constantName, mc.name);
				(mc.hidden ? linesHide : linesShow).push(procMc(
					name, mc.value, mc.hidden));
			}
			//
			procSortAuto(linesShow);
			if (out != "") out += "\n";
			out += "#section " + file.filename;
			for (line in linesShow) out += "\n" + line;
			//
			if (linesHide.length > 0) {
				procSortAuto(linesHide);
				out += "\n#section " + file.filename + " (hidden)";
				for (line in linesHide) out += "\n" + line;
			}
		}
		return out;
	}
}
