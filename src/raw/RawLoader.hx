package raw;
import electron.FileSystem;
import gml.Project;
import haxe.io.Path;
import js.html.Element;
import ui.treeview.TreeView;
import gml.GmlAPI;
import parsers.GmlSeeker;
import ace.extern.*;
using tools.PathTools;

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
		var topLevel = TreeView.makeAssetDir(project.displayName, "", "file");
		topLevel.treeIsOpen = true;
		topLevel.treeHeader.classList.add("hidden");
		TreeView.element.appendChild(topLevel);
		loadDirRec(project, topLevel.treeItems, "");
		GmlSeeker.start();
		GmlAPI.gmlClear();
		GmlAPI.extClear();
		var wantIndex = (project.version.config.indexingMode == Directory);
		for (item in tools.HtmlTools.querySelectorEls(topLevel, "div." + TreeView.clItem)) {
			var full = item.getAttribute(TreeView.attrPath);
			if (full == null) continue;
			var rel = item.getAttribute(TreeView.attrRel);
			GmlAPI.gmlLookup.set(rel, {
				path: full,
				sub: null,
				row: 0,
			});
			GmlAPI.gmlLookupList.push(rel);
			if (!wantIndex || full.ptExt() != "gml") continue;
			// is a script
			var name = full.ptNoDir().ptNoExt();
			GmlSeeker.run(full, name, file.kind.gml.KGmlScript.inst);
			GmlAPI.gmlKind[name] = "asset.script";
			var comp = new AceAutoCompleteItem(name, "script");
			GmlAPI.gmlComp.push(comp);
			GmlAPI.gmlAssetComp.set(name, comp);
		}
	}
}
