package raw;
import electron.FileSystem;
import gml.Project;
import haxe.io.Path;
import js.html.Element;
import ui.treeview.TreeView;

/**
 * ...
 * @author YellowAfterlife
 */
class RawLoader {
	public static function loadDirRec(project:Project, out:Element, dirPath:String):Void {
		var dirPairs = project.readdirSync(dirPath);
		// directories first, files after
		for (dirPass in 0 ... 2) for (pair in dirPairs) {
			if (pair.isDirectory != (dirPass == 0)) continue;
			var item = pair.fileName;
			var rel = Path.join([dirPath, item]);
			if (pair.isDirectory) {
				var nd = TreeView.makeAssetDir(item, rel, "file");
				loadDirRec(project, nd.treeItems, rel);
				out.appendChild(nd);
			} else {
				var full = project.fullPath(rel);
				var item = TreeView.makeAssetItem(item, rel, full, "file");
				out.appendChild(item);
				//
				if (ui.Preferences.current.assetThumbs)
				switch (Path.extension(full).toLowerCase()) {
					case "png", "jpg", "jpeg", "gif", "bmp": {
						TreeView.setThumb(full, full, item);
					};
				}
			}
		}
	}
	public static function run(project:Project) {
		TreeView.clear();
		var topLevel = TreeView.makeAssetDir(project.name, "", "file");
		topLevel.classList.add(TreeView.clOpen);
		TreeView.element.appendChild(topLevel);
		loadDirRec(project, topLevel.treeItems, "");
	}
}
