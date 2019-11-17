package file.kind.yy;
import yy.YyExtension;
import yy.YyJson;
import ui.treeview.TreeView;
import gml.GmlAPI;
import ace.extern.*;
import haxe.io.Path;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class KYyExtension extends FileKind {
	public static var inst:KYyExtension = new KYyExtension();
	override public function index(path:String, content:String, main:String):Bool {
		var ext:YyExtension = YyJson.parse(content);
		//
		var parentPath = ext.parent.path;
		if (parentPath.endsWith(".yy")) {
			parentPath = parentPath.substring(0, parentPath.length - 3);
		}
		var parentDir = TreeView.find(false, { rel: parentPath });
		if (parentDir == null) return true;
		var treePath = parentPath + "/" + ext.name;
		var treeDir = TreeView.makeAssetDir(ext.name, parentPath, "mixed");
		TreeView.insertSorted(cast parentDir, treeDir);
		//
		var extDirRel = Path.directory(path);
		var full = gml.Project.current.fullPath(path);
		var extDir = Path.directory(full);
		for (file in ext.files) {
			// todo: this is too alike with V22 and I don't like that
			var fileName = file.filename;
			var filePath = Path.join([extDir, fileName]);
			var filePathRel = Path.join([extDirRel, fileName]);
			var fileItem = TreeView.makeAssetItem(fileName, filePathRel, filePath, "file");
			TreeView.insertSorted(treeDir, fileItem);
			var isGmlFile = Path.extension(fileName).toLowerCase() == "gml";
			for (func in file.functions) {
				var name = func.name;
				var help = func.help;
				GmlAPI.extKind.set(name, "extfunction");
				GmlAPI.extArgc[name] = func.argCount < 0 ? func.argCount : func.args.length;
				if (help != null && help != "" && !func.hidden) {
					GmlAPI.extCompAdd(new AceAutoCompleteItem(
						name, "function", help
					));
					GmlAPI.extDoc.set(name, gml.GmlFuncDoc.parse(help));
					if (isGmlFile) GmlAPI.gmlLookupText += name + "\n";
				}
				if (isGmlFile) {
					GmlAPI.gmlLookup.set(name, {
						path: filePath,
						sub: name,
						row: 0,
					});
				}
			}
			for (mcr in file.constants) {
				var name = mcr.constantName;
				GmlAPI.extKind.set(name, "extmacro");
				if (!mcr.hidden) {
					var expr = mcr.value;
					GmlAPI.extCompAdd(new AceAutoCompleteItem(
						name, "macro", expr
					));
				}
			}
		}
		trace(ext);
		return true;
	}
}