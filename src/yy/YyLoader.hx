package yy;
import ace.extern.*;
import electron.FileSystem;
import electron.FileWrap;
import gml.GmlAPI;
import gml.Project;
import js.lib.RegExp;
import js.html.Console;
import synext.GmlExtLambda;
import parsers.GmlSeeker;
import haxe.io.Path;
import js.html.Element;
import tools.Dictionary;
import tools.ExecQueue;
import tools.JsTools;
import ui.Preferences;
using StringTools;
using tools.NativeString;
using tools.NativeArray;
import yy.YyProject;
import ui.treeview.TreeView;
import ui.treeview.TreeViewElement;
import file.kind.gml.*;
import file.kind.yy.*;
import file.kind.misc.*;
using tools.PathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class YyLoader {
	static var nextYypContent:String = null;
	
	/** Only to be used during indexing */
	static var folderMap:Dictionary<TreeViewDir> = null;
	
	static var itemsToInsert:Array<{item:TreeViewElement,dir:TreeViewDir}> = null;
	
	static var rxV23 = new RegExp('"resourceType":[ ]*"GMProject"');
	public static inline function isV23(yypContent:String) {
		return yypContent.contains('"resourceType":') && rxV23.test(yypContent);
	}
	
	static var assetColours:Dictionary<Array<String>> = new Dictionary();
	public static function applyAssetColour(el:TreeViewElement, path:String) {
		var colors = assetColours[path.ptNoBS()];
		if (colors != null) {
			el.style.setProperty("--data-color", colors[0]);
			el.setAttribute("data-color", colors[0]);
			if (el.treeIsDir) {
				var items = el.asTreeDir().treeItems;
				items.style.setProperty("--data-color", colors[1]);
				items.setAttribute("data-color", colors[1]);
			}
		}
	}
	public static function run(project:Project):Void {
		var yyProjectTxt:String;
		if (nextYypContent != null) {
			yyProjectTxt = nextYypContent;
			nextYypContent = null;
		} else yyProjectTxt = project.readTextFileSync(project.name);
		//
		if (isV23(yyProjectTxt)) {
			project.yyExtJson = true;
			project.yyUsesGUID = false;
			project.isGMS23 = true;
		} else {
			assetColours = new Dictionary();
			yy.v22.YyLoaderV22.run(project, YyJson.parse(yyProjectTxt));
			return;
		}
		project.hasGMLive = yyProjectTxt.contains('"path":"scripts/GMLive/GMLive.yy"');
		var yyProject:YyProject = YyJsonParser.parse(yyProjectTxt);
		if (project.isGMS23) {
			var metaData = yyProject.MetaData;
			if (metaData != null && metaData.IDEVersion != null) {
				var mt = new RegExp("^(20\\d{2})\\.(\\d+)?").exec(metaData.IDEVersion);
				var year = null, mon = null;
				if (mt != null) {
					year = Std.parseInt(mt[1]);
					mon = Std.parseInt(mt[2]);
				}
				if (year == null) year = 0;
				if (mon == null) mon = 0;
				project.isGM2022 = year >= 2022;
				project.isGM2023 = year >= 2023;
				project.isGM2024 = year >= 2024 || yyProjectTxt.contains("\"$GMProject\":");
				project.isGM2024_8 = project.isGM2024 && mon >= 8;
				project.usesResourceOrderFile = project.isGM2023 && project.existsSync(project.getResourceOrderFilePath());
				project.yyResourceVersion = try {
					Std.parseFloat(yyProject.resourceVersion);
				} catch (x:Dynamic) 1.0;
			}
		}
		//
		var resourceOrder:YyResourceOrderSettings = null;
		if (project.usesResourceOrderFile) try {
			resourceOrder = project.readYyFileSync(project.getResourceOrderFilePath());
		} catch (x:Dynamic) {
			Console.error("Failed to read resource order file:", x);
			project.usesResourceOrderFile = false;
		}
		//
		assetColours = new Dictionary();
		var pjName = Path.withoutExtension(project.name);
		for (dir in Preferences.userPaths) try {
			var abPath = '$dir/Layouts/$pjName/$pjName/asset_browser.json';
			if (!FileSystem.existsSync(abPath)) continue;
			var ab:YyAssetBrowserData = FileSystem.readYyFileSync(abPath);
			var abc = ab.AssetColours;
			if (abc != null) for (pair in abc) {
				var c = pair.Value;
				var colors = [c.toCSS(), c.toAlphaCSS(0.5)];
				var path:String;
				if (pair.Key is String) {
					path = pair.Key;
				} else path = (pair.Key:YyResourceRef).path;
				assetColours[path.replace("\\", "/")] = colors;
			}
		} catch (x:Dynamic) Console.error(x);
		//
		var folderMap = new Dictionary<TreeViewDir>();
		itemsToInsert = [];
		YyLoader.folderMap = folderMap;
		var folderPairs = [];
		for (folder in yyProject.Folders) {
			//
			var folderPathYY = folder.folderPath;
			var folderPath = folderPathYY;
			if (folderPath.endsWith(".yy")) {
				folderPath = folderPath.substring(0, folderPath.length - 3);
			}
			//
			var folderDir = TreeView.makeAssetDir(folder.name, folderPath + "/", "mixed");
			var folderOrder = folder.order ?? 0;
			if (resourceOrder != null) {
				var folder2 = resourceOrder.FolderOrderSettings.findFirst((f)->f.path == folderPathYY);
				if (folder2 != null) folderOrder = folder2.order;
			}
			folderDir.yyOrder = folderOrder;
			folderMap[folderPath] = folderDir;
			folderPairs.push({
				dir: folderDir,
				path: folderPath,
			});
			applyAssetColour(folderDir, folderPathYY);
		}
		//
		TreeView.saveOpen();
		TreeView.clear();
		//
		GmlSeeker.start();
		GmlAPI.gmlClear();
		GmlAPI.extClear();
		//
		var topLevel = TreeView.makeAssetDir(project.displayName, "", "mixed");
		topLevel.classList.add(TreeView.clOpen);
		topLevel.treeHeader.classList.add("hidden");
		topLevel.treeRelPath = project.name;
		TreeView.element.appendChild(topLevel);
		folderMap["folders"] = topLevel;
		//
		for (pair in folderPairs) {
			var folderPath = pair.path;
			var lastSlash = folderPath.lastIndexOf("/");
			var parentPath = folderPath.substring(0, lastSlash);
			var parentDir = folderMap[parentPath];
			if (parentDir == null) {
				Console.log("Folder without parent", folderPath);
				continue;
			}
			if (parentDir == pair.dir) continue;
			TreeView.insertSorted(parentDir, pair.dir);
		}
		inline function getRoomsFolder():TreeViewDir {
			return JsTools.orx(
				folderMap["folders/Rooms"],
				folderMap["folders/rooms"],
				topLevel
			);
		}
		if (true) { // RoomOrder
			var ord = TreeView.makeAssetItem("Room Order",
				project.name, project.path, "roomorder"
			);
			ord.removeAttribute(TreeView.attrThumb);
			ord.yyOpenAs = KYyRoomOrder.inst;
			ord.yyOrder = -1;
			getRoomsFolder().treeItems.appendChild(ord);
		}
		if (true) { // RoomCCs
			var ccs = TreeView.makeAssetItem("Room Creation Codes",
				project.name, project.path, "roomccs");
			ccs.removeAttribute(TreeView.attrThumb);
			ccs.yyOpenAs = KYyRoomCCs.inst;
			ccs.yyOrder = -1;
			getRoomsFolder().treeItems.appendChild(ccs);
		}
		if (project.existsSync("#import")) {
			var idir = TreeView.makeAssetDir("Imports", "#import/", "file");
			raw.RawLoader.loadDirRec(project, idir.treeItems, "#import");
			topLevel.treeItems.appendChild(idir);
		}
		if (project.existsSync("datafiles")) {
			var idir = TreeView.makeAssetDir("Included Files", "datafiles/", "file");
			raw.RawLoader.loadDirRec(project, idir.treeItems, "datafiles");
			var items = tools.HtmlTools.querySelectorAllAuto(idir, "div." + TreeView.clItem, TreeViewItem);
			for (item in items) {
				var rel = item.treeRelPath;
				GmlAPI.gmlLookup.set(rel, { path: item.treeFullPath, row: 0 });
				GmlAPI.gmlLookupItems.push({ value: rel, meta:"includedFile" });
			}
			topLevel.treeItems.appendChild(idir);
		}
		if (project.existsSync("options")) {
			var optDir = TreeView.makeAssetDir("Options", "options/", "options");
			for (item in project.readdirSync("options")) {
				if (!item.isDirectory) continue;
				for (subitem in project.readdirSync(item.relPath)) {
					if (subitem.isDirectory) continue;
					if (subitem.relPath.ptExt() != "yy") continue;
					var optItem = TreeView.makeAssetItem(
						item.relPath.ptName(),
						subitem.relPath,
						subitem.fullPath,
						"options",
					);
					optItem.yyOpenAs = file.kind.misc.KJavaScript.inst;
					optDir.treeItems.appendChild(optItem);
				}
			}
			topLevel.treeItems.appendChild(optDir);
		}
		// restoreOpen runs in Project:reload
		project.yyObjectNames = new Dictionary();
		project.yyObjectGUIDs = new Dictionary();
		project.yyResources = new Dictionary();
		project.yyResourceGUIDs = new Dictionary();
		project.yySpriteURLs = new Dictionary();
		project.yyResourceTypes = new Dictionary();
		project.yyOrder = new Dictionary();
		project.resourceTypes = new Dictionary();
		for (resource in yyProject.resources) {
			var resPath = resource.id.path;
			var resName = resource.id.name;
			project.yyOrder[resName] = resource.order ?? 0;
			// get rid of this mess later
			project.yyResources[resName] = resource;
			project.yyResourceGUIDs[resName] = cast resName;
			project.setResourceTypeFromPath(resPath, resName);
			//
			if (resPath.startsWith("objects/")) {
				project.yyObjectNames[resName] = resName;
				project.yyObjectGUIDs[resName] = cast resName;
			}
		}
		if (resourceOrder != null) for (ordItem in resourceOrder.ResourceOrderSettings) {
			project.yyOrder[ordItem.name] = ordItem.order;
		}
		//
		for (resource in yyProject.resources) {
			GmlSeeker.run(resource.id.path, resource.id.name, KYyUnknown.inst);
		}
		project.yyTextureGroups = new Array();
		for (texturepage in yyProject.TextureGroups) {
			project.yyTextureGroups.push(texturepage.name);
		}
		//
		if (yyProject.AudioGroups != null) for (ag in yyProject.AudioGroups) {
			GmlAPI.gmlKind[ag.name] = "asset.audio_group";
			var ac = new AceAutoCompleteItem(ag.name, "audio_group");
			GmlAPI.gmlAssetComp[ag.name] = ac;
			GmlAPI.gmlComp.push(ac);
		}
	}
}
private class YyLoaderFolder {
	public var dir:TreeViewDir;
	public var path:String;
	public var children:Array<YyLoaderItem> = [];
	public function new(base:YyProjectFolder) {
		
	}
}
private class YyLoaderItem {
	public var name:String;
	public var item:TreeViewItem;
	public function new(name:String) {
		this.name = name;
	}
}
