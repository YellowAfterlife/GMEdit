package yy.zip;
import gml.Project;
import haxe.io.Path;
import js.lib.RegExp;
import js.html.FormElement;
import js.html.InputElement;
import yy.zip.YyZip;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class YyZipDirectoryDialog {
	private static var form:FormElement = null;
	private static var input:InputElement;
	private static function init() {
		var form = Main.document.createFormElement();
		var input = Main.document.createInputElement();
		input.setAttribute("webkitdirectory", "");
		input.setAttribute("mozdirectory", "");
		input.type = "file";
		//var v:Project
		input.addEventListener("change", check);
		form.appendChild(input);
		Main.document.body.appendChild(form);
		YyZipDirectoryDialog.form = form;
		YyZipDirectoryDialog.input = input;
	}
	private static function check(_) {
		var main = null;
		var entries:Array<YyZipFile> = [];
		var left = 1;
		function next() {
			if (--left > 0) return;
			var main = YyZipTools.locateMain(entries);
			if (main == null) {
				Main.window.alert("Couldn't find any project files in directory");
				return;
			}
			// unpack entries from directory, where possible:
			do {
				var mt = new RegExp("^.+?[\\/]").exec(main);
				if (mt == null) break;
				var dir = mt[0];
				// ensure that all entries start with this path:
				var i = entries.length;
				while (--i >= 0) if (!entries[i].path.startsWith(dir)) break;
				if (i >= 0) break;
				// crop it off:
				var start = dir.length;
				i = entries.length;
				while (--i >= 0) entries[i].trimStart(start);
				main = main.substring(start);
			} while (false);
			//
			Project.setCurrent(new YyZip(main, main, entries));
		}
		//
		var files = input.files;
		if (files.length == 0) return;
		var status = "Loading " + files.length + " file";
		if (files.length != 1) status += "s";
		tools.HtmlTools.setInnerText(Project.nameNode, status + "...");
		//
		for (file in files) {
			var rel = untyped file.webkitRelativePath;
			if (main == null) {
				var ext = Path.extension(rel);
				if (ext.toLowerCase() != "yyp") {
					ext = Path.extension(Path.withoutExtension(rel)).toLowerCase();
					if (ext.toLowerCase() != "project") {
						var lqr = Path.withoutDirectory(rel).toLowerCase();
						if (lqr == "main.txt" || lqr == "main.cfg") main = rel;
					} else main = rel;
				} else main = rel;
			}
			//
			var reader = new js.html.FileReader();
			reader.onloadend = function(_) {
				var abuf:js.lib.ArrayBuffer = reader.result;
				var bytes = haxe.io.Bytes.ofData(abuf);
				var zipFile = new YyZipFile(rel, file.lastModified);
				zipFile.setBytes(bytes);
				entries.push(zipFile);
				next();
			};
			left += 1;
			reader.readAsArrayBuffer(file);
		}
		next();
	}
	public static function open() {
		if (form == null) init();
		form.reset();
		input.click();
	}
}