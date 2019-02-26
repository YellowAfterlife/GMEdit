package file.kind.gml;
import editors.EditCode;
import electron.Dialog;
import electron.FileWrap;
import gml.file.GmlFileExtra;
import parsers.GmlMultifile;
import parsers.GmlSeeker;
import tools.Dictionary;
import tools.NativeArray;
import tools.NativeString;

/**
 * The "Open in a combined view" option
 * @author YellowAfterlife
 */
class KGmlMultifile extends KGml {
	public static var inst:KGmlMultifile = new KGmlMultifile();
	public function new() {
		super();
		canImport = false;
		canLambda = false;
		checkSelfForChanges = false;
	}
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		var file = editor.file;
		if (data != null) file.multidata = data;
		NativeArray.clear(file.extraFiles);
		var out = "";
		var errors = "";
		for (item in file.multidata) {
			if (out != "") out += "\n\n";
			out += "#define " + item.name + "\n";
			var itemCode = FileWrap.readTextFileSync(item.path);
			var itemSubs = GmlMultifile.split(itemCode, item.name);
			if (itemSubs == null) {
				errors += "Can't open " + item.name
					+ " for editing: " + GmlMultifile.errorText + "\n";
			} else switch (itemSubs.length) {
				case 0: { };
				case 1: {
					var subCode = itemSubs[0].code;
					out += NativeString.trimRight(subCode);
				};
				default: errors += "Can't open " + item.name
					+ " for editing because it contains multiple scripts.\n";
			}
			file.extraFiles.push(new GmlFileExtra(item.path));
		}
		if (errors == "") {
			// (too buggy)
			//out = GmlExtArgs.pre(out);
			//out = GmlExtImport.pre(out, path);
			GmlSeeker.runSync(file.path, out, "", file.kind);
			return out;
		} else return editor.setLoadError(errors);
	}
	override public function saveCode(editor:EditCode, code:String):Bool {
		code = super.postproc(editor, code);
		if (code == null) return null;
		var file = editor.file;
		var next = GmlMultifile.split(code, "<detached code>");
		var map0 = new Dictionary<String>();
		for (item in file.multidata) map0.set(item.name, item.path);
		var errors = "";
		for (item in next) {
			var itemPath = map0[item.name];
			if (itemPath != null) {
				var itemCode = item.code;
				FileWrap.writeTextFileSync(itemPath, itemCode);
			} else errors += "Can't save script " + item.name
				+ " because it is not among the edited group.\n";
		}
		if (errors != "") {
			Dialog.showError(errors);
			return false;
		} else return true;
	}
}
