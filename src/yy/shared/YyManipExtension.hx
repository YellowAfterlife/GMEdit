package yy.shared;
import electron.FileSystem;
import electron.FileWrap;
import gml.Project;
import haxe.io.Path;
import tools.Aliases;
import ui.treeview.TreeView;
import ui.treeview.TreeViewElement.TreeViewDir;
import yy.YyExtension;
import js.html.Console;
using tools.NativeArray;

/**
 * ...
 * @author YellowAfterlife
 */
class YyManipExtension {
	public static function addFiles(tvDir:TreeViewDir, extensionPath:FullPath, filePaths:Array<FullPath>) {
		var extStr = FileWrap.readTextFileSync(extensionPath);
		var ext:YyExtension = YyJson.parse(extStr, true); // need to use a parser not to ruin 64-bit flags
		var extDir = Path.directory(extensionPath);
		var extDirRel = Project.current.relPath(extDir) ?? extDir;
		var changed = false;
		var v23 = Project.current.isGMS23;
		for (srcFull in filePaths) {
			var rel = Path.withoutDirectory(srcFull);
			var dstFull = extDir + "/" + rel;
			
			try {
				FileSystem.copyFileSync(srcFull, dstFull);
			} catch (x:Dynamic) {
				Console.error(x);
			}
			
			var ref = ext.files.findFirst(function(file) {
				return file.filename == rel;
			});
			if (ref != null) {
				// trying to add the file that's already here?
				if (Path.normalize(srcFull) == Path.normalize(dstFull)) continue;
				continue;
			}
			
			var file:YyExtensionFile;
			file = {
				filename: rel,
				origname: "extensions\\" + rel,
				init: "",
				kind: YyExtensionFileKind.detect(dstFull),
				uncompress: false,
				functions: [],
				constants: [],
				ProxyFiles: [],
				copyToTargets: -1,
				order: [],
			};
			file.finalizer = "";
			
			if (v23) {
				file.resourceVersion = "1.0";
				file.name = "";
				file.tags = [];
				file.resourceType = "GMExtensionFile";
			} else {
				file.id = new YyGUID();
				file.modelName = "GMExtensionFile";
				file.mvc = "1.0";
			}
			
			
			ext.files.push(file);
			var filePath = Path.join([extDir, rel]);
			var filePathRel = Path.join([extDirRel, rel]);
			var fileItem = TreeView.makeAssetItem(rel, filePathRel, filePath, "file");
			tvDir.treeItems.appendChild(fileItem);
			
			changed = true;
		}
		if (changed) {
			FileWrap.writeTextFileSync(extensionPath, YyJson.stringify(ext, v23));
			//Project.current.reload();
		}
	}
	public static function deleteFile(extensionPath:FullPath, filename:RelPath) {
		var ext:YyExtension = FileWrap.readYyFileSync(extensionPath);
		var fileToDelete = ext.files.findFirst(function(file) return file.filename == filename);
		if (fileToDelete == null) return false;
		var filePath = Path.directory(extensionPath) + "/" + filename;
		try {
			FileWrap.unlinkSync(filePath);
		} catch (_) {}
		ext.files.remove(fileToDelete);
		FileWrap.writeYyFileSync(extensionPath, ext, Project.current.isGMS23);
		return true;
	}
}