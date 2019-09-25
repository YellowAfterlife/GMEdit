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
		for (pair in project.readdirSync(dirPath)) {
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
		var pfx = Std.is(project, yy.YyZip) ? "" : project.dir;
		var ths = [];
		function loadrec(out:Element, dirFull:String, dirRel:String):Void {
			var rd = [], rf = [];
			for (pair in project.readdirSync(dirFull)) {
				var item = pair.fileName;
				var full = Path.join([dirFull, item]);
				var rel = Path.join([dirRel, item]);
				if (pair.isDirectory) {
					var nd = TreeView.makeAssetDir(item, rel, "file");
					loadrec(nd.treeItems, full, rel);
					rd.push(nd);
				} else {
					var ifull = Path.join([pfx, full]);
					var item = TreeView.makeAssetItem(item, rel, ifull, "file");
					rf.push(item);
					if (ui.Preferences.current.assetThumbs)
					switch (Path.extension(full).toLowerCase()) {
						case "png", "jpeg", "gif": {
							ths.push({ path: ifull, th: full, item: item });
						};
					}
				}
			}
			for (el in rd) out.appendChild(el);
			for (el in rf) out.appendChild(el);
		}
		TreeView.clear();
		loadrec(TreeView.element, "", "");
		for (pair in ths) {
			TreeView.setThumb(pair.path, project.fullPath(pair.th), pair.item);
		}
	}
}
