package gmk;
import ace.extern.AceAutoCompleteItem;
import file.FileKind;
import file.kind.gmk.*;
import file.kind.gml.KGmlScript;
import gml.GmlAPI;
import gml.Project;
import haxe.io.Path;
import parsers.GmlSeeker;
import tools.Aliases;
import ui.treeview.TreeView;
import ui.treeview.TreeViewElement;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmkLoader {
	public static function run(project:Project) {
		//
		GmlSeeker.start();
		GmlAPI.gmlClear();
		GmlAPI.extClear();
		//
		function loadRec(dir:FullPath, kind:String, suffix:String, parDir:TreeViewDir):Void {
			var rxml = '$dir/_resources.list.xml';
			if (!project.existsSync(rxml)) return;
			var xml = project.readGmxFileSync(rxml);
			for (item in xml.children) {
				var name = item.get("name");
				var fname = item.get("filename");
				if (fname == null) fname = name;
				var rel = '$dir/$fname';
				if (item.get("type") == "GROUP") {
					var tvDir = TreeView.makeAssetDir(name, rel, kind);
					loadRec(rel, kind, suffix, tvDir);
					parDir.treeItems.appendChild(tvDir);
					continue;
				}
				rel += suffix;
				var full = project.fullPath(rel);
				//
				GmlAPI.gmlLookupText += name + "\n";
				if (name == fname) { // valid identifier
					GmlAPI.gmlKind[name] = "asset." + kind;
					var ac = new AceAutoCompleteItem(name, kind);
					GmlAPI.gmlAssetComp[name] = ac;
					GmlAPI.gmlComp.push(ac);
				}
				//
				var openAs:FileKind = null;
				var indexKind:FileKind = null;
				switch (kind) {
					case "script": indexKind = KGmlScript.inst;
					case "object": {
						openAs = indexKind = KGmkEvents.inst;
					};
					case "sprite": full = Path.withExtension(full, "images");
					case "background": full = Path.withExtension(full, "png");
				}
				if (indexKind != null) GmlSeeker.run(full, name, indexKind);
				//
				var tvItem = TreeView.makeAssetItem(name, rel, full, kind);
				if (openAs != null) tvItem.yyOpenAs = openAs;
				parDir.treeItems.appendChild(tvItem);
				//
				if (ui.Preferences.current.assetThumbs) switch (kind) {
					case "sprite": {
						var url = project.getImageURL('sprites/$fname.images/image 0.png');
						TreeView.setThumb(null, url, tvItem);
					};
					case "background": {
						var url = project.getImageURL('Backgrounds/$fname.png');
						TreeView.setThumb(null, url, tvItem);
					};
				}
			}
		}
		function loadRecRoot(dir:FullPath, kind:String, suffix:String):Void {
			var tvDir = TreeView.makeAssetDir(dir, dir, kind);
			loadRec(dir, kind, suffix, tvDir);
			TreeView.element.appendChild(tvDir);
		}
		var baseDir = project.dir;
		loadRecRoot("Sprites", "sprite", ".xml");
		loadRecRoot("Sounds", "sound", ".xml");
		loadRecRoot("Backgrounds", "background", ".xml");
		loadRecRoot("Paths", "path", ".xml");
		loadRecRoot("Scripts", "script", ".gml");
		loadRecRoot("Fonts", "font", ".xml");
		loadRecRoot("Time Lines", "timeline", ".xml");
		loadRecRoot("Objects", "object", ".xml");
		loadRecRoot("Rooms", "room", ".xml");
		//
	}
}