package gmk.gm82;

import haxe.io.Bytes;
import js.lib.Uint8Array;
import electron.FileSystem;
import electron.Electron;
import js.html.Console;
import ui.Preferences;
import ace.extern.AceAutoCompleteItem;
import file.kind.gmk.*;
import file.kind.gml.*;
import file.FileKind;
import ui.treeview.TreeViewElement;
import js.lib.RegExp;
import haxe.io.Path;
import tools.Aliases;
import ui.treeview.TreeView;
import gml.GmlAPI;
import parsers.GmlSeeker;
import gml.Project;
using StringTools;
using tools.NativeString;

class Gm82Loader {
	public static function run(project:Project) {
		//
		GmlSeeker.start();
		GmlAPI.gmlClear();
		GmlAPI.extClear();
		TreeView.clear();
		//
		var assetThumbs = ui.Preferences.current.assetThumbs;
		var seekSoon = [];
		project.resourceTypes = new tools.Dictionary();
		function loadRecRoot(dir:RelPath, kind:String) {
			if (!project.existsSync(dir)) return;
			var treePath = Path.join([dir, "tree.yyd"]);
			if (!project.existsSync(treePath)) return;
			//
			var rootDir = TreeView.makeAssetDir(dir.capitalize(), dir, kind);
			var treeDirs:Array<TreeViewDir> = [rootDir];
			var treeNames:Array<String> = [];
			//
			var yydText = project.readTextFileSync(treePath);
			var yydLines = yydText.trim().replace("\r", "").split("\n");
			var rxTabs = new RegExp("^(\t*)([\\+\\|])(.*)");
			//
			for (line in yydLines) {
				var mt = rxTabs.exec(line);
				if (mt == null) continue;
				var level = mt[1].length;
				var isDir = mt[2] == "+";
				var name = mt[3];
				if (isDir) {
					var relPath = treeNames.slice(0, level + 1).join("/");
					var treeDir = TreeView.makeAssetDir(name, relPath, kind);
					treeDirs[level + 1] = treeDir;
					treeNames[level + 1] = name;
					treeDirs[level].treeItems.appendChild(treeDir);
					continue;
				}
				//
				var assetKind = "asset." + kind;
				GmlAPI.gmlLookupItems.push({ value:name, meta: assetKind });
				GmlAPI.gmlKind[name] = assetKind;
				var ac = new AceAutoCompleteItem(name, kind);
				GmlAPI.gmlAssetComp[name] = ac;
				GmlAPI.gmlComp.push(ac);
				//
				var openAs:FileKind = null;
				var indexKind:FileKind = null;
				var relPath:String = null;
				switch (kind) {
					case "script": {
						indexKind = KGmlScript.inst;
						relPath = 'scripts/$name.gml';
					};
					case "object": {
						openAs = indexKind = KGm82Events.inst;
						relPath = 'objects/$name.gml';
					};
					case "sprite": {
						relPath = 'sprites/$name';
					};
					case "room": {
						relPath = 'rooms/$name';
					}
					default: {
						relPath = '$dir/$name.txt';
					}
				}
				var fullPath = project.fullPath(relPath);
				if (indexKind != null) {
					seekSoon.push({ full: fullPath, name: name, kind: indexKind });
				}
				//
				var tvItem = TreeView.makeAssetItem(name, relPath, fullPath, kind);
				if (openAs != null) tvItem.yyOpenAs = openAs;
				treeDirs[level].treeItems.appendChild(tvItem);
				//
				if (assetThumbs) switch (kind) {
					case "sprite": {
						var first = relPath + "/0.png";
						if (project.existsSync(first)) {
							var url = project.getImageURL(first);
							TreeView.setThumb(null, url, tvItem);
						}
					}
				}
			} // for line
			TreeView.element.appendChild(rootDir);
		}
		loadRecRoot("sprites", "sprite");
		loadRecRoot("sounds", "sound");
		loadRecRoot("backgrounds", "background");
		loadRecRoot("paths", "path");
		loadRecRoot("scripts", "script");
		loadRecRoot("fonts", "font");
		loadRecRoot("timelines", "timeline");
		loadRecRoot("objects", "object");
		loadRecRoot("rooms", "room");
		//
		{ // constants
			var constRel = "settings/constants.txt";
			var constFull = project.fullPath(constRel);
			var tvItem = TreeView.makeAssetItem("Constants", constRel, constFull, "script");
			tvItem.yyOpenAs = KGm82Constants.inst;
			TreeView.element.appendChild(tvItem);
			if (project.existsSync(constRel)) seekSoon.push({
				full: constFull,
				name: "Constants",
				kind: KGm82Constants.inst
			});
		}
		//
		var extensionList = project.readTextFileSync("settings/extensions.txt").replace("\r", "");
		var extensionFolder = Preferences.current.gmkExtensionFolder;
		for (extName in extensionList.split("\n")) {
			extName = extName.trim();
			if (extName == "") continue;
			//
			if (extensionFolder == null || extensionFolder == "") {
				Console.warn('Project uses extension "$extName" but extension folder is not set in Preferences.');
				continue;
			}
			//
			var path = Path.join([extensionFolder, extName + ".ged"]);
			if (!FileSystem.existsSync(path)) {
				Console.warn('Project uses extension "$extName" but it\'s not in the extension folder.');
				continue;
			}
			//
			try {
				var raw = FileSystem.readFileSync(path);
				var ua:Uint8Array = untyped Uint8Array.from(raw);
				var abuf = ua.buffer;
				GedLoader.run(Bytes.ofData(abuf));
			} catch (x:Dynamic) {
				Console.error('Failed to index extension "$extName": $x');
			}
		}
		//
		
		//
		for (item in seekSoon) {
			GmlSeeker.run(item.full, item.name, item.kind);
		}
	}
}