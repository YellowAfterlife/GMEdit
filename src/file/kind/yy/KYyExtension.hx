package file.kind.yy;
import file.kind.gml.KGmlExtension;
import js.lib.RegExp;
import parsers.GmlSeeker;
import parsers.GmlSeekData;
import yy.YyExtension;
import yy.YyJson;
import ui.treeview.TreeView;
import gml.GmlAPI;
import ace.extern.*;
import haxe.io.Path;
import yy.YyLoader;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class KYyExtension extends FileKind {
	public static var inst:KYyExtension = new KYyExtension();
	static var rxValidName:RegExp = new RegExp("^\\w+$");
	override public function index(full:String, content:String, main:String, sync:Bool):Bool {
		var ext:YyExtension = YyJson.parse(content);
		var pj = gml.Project.current;
		var extDirRel = pj.relPath(full);
		var extDir = Path.directory(full);
		//
		var parentPath = ext.parent.path;
		if (parentPath.endsWith(".yy")) {
			parentPath = parentPath.substring(0, parentPath.length - 3);
		}
		//
		var parentDir = @:privateAccess YyLoader.folderMap[parentPath];
		if (parentDir == null) parentDir = cast TreeView.find(false, { rel: parentPath });
		if (parentDir == null) return true;
		//
		var treePath = parentPath + "/" + ext.name;
		var treeDir = TreeView.makeAssetDir(ext.name, treePath, "extension");
		treeDir.treeFullPath = full;
		treeDir.treeIdent = ext.name;
		@:privateAccess YyLoader.itemsToInsert.push({
			item: treeDir,
			dir: cast parentDir
		});
		//
		for (file in ext.files) {
			// todo: this is too alike with V22 and I don't like that
			var fileName = file.filename;
			var filePath = Path.join([extDir, fileName]);
			var filePathRel = Path.join([extDirRel, fileName]);
			var fileItem = TreeView.makeAssetItem(fileName, filePathRel, filePath, "file");
			@:privateAccess YyLoader.itemsToInsert.push({
				item: fileItem,
				dir: treeDir
			});
			var isGmlFile = Path.extension(fileName).toLowerCase() == "gml";
			for (func in file.functions) {
				var name = func.name;
				if (!rxValidName.test(name)) continue;
				var help = func.help;
				GmlAPI.extKind.set(name, "extfunction");
				GmlAPI.extArgc[name] = func.argCount < 0 ? func.argCount : func.args.length;
				if (help != null && help != "" && !func.hidden) {
					GmlAPI.extCompAdd(new AceAutoCompleteItem(
						name, "function", help
					));
					GmlAPI.extDoc.set(name, gml.GmlFuncDoc.parse(help));
					if (isGmlFile) GmlAPI.gmlLookupItems.push({value:name, meta:"extfunction"});
				}
				if (isGmlFile) {
					GmlAPI.gmlLookup.set(name, {
						path: filePath,
						sub: name,
						row: 0,
					});
				}
			}
			if (isGmlFile) GmlSeeker.run(filePath, "", KGmlExtension.inst);
			for (mcr in file.constants) {
				var name = mcr.name;
				if (!rxValidName.test(name)) continue;
				GmlAPI.extKind.set(name, "extmacro");
				if (!mcr.hidden) {
					var expr = mcr.value;
					GmlAPI.extCompAdd(new AceAutoCompleteItem(
						name, "macro", expr
					));
				}
			}
		}
		return true;
	}
}