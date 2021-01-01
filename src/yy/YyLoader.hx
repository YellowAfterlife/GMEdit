package yy;
import ace.extern.*;
import electron.FileSystem;
import electron.FileWrap;
import gml.GmlAPI;
import gml.Project;
import js.lib.RegExp;
import synext.GmlExtLambda;
import parsers.GmlSeeker;
import haxe.io.Path;
import js.html.Element;
import tools.Dictionary;
import tools.ExecQueue;
import tools.JsTools;
using tools.NativeString;
using tools.NativeArray;
import yy.YyProject;
import ui.treeview.TreeView;
import ui.treeview.TreeViewElement;
import file.kind.gml.*;
import file.kind.yy.*;
import file.kind.misc.*;

/**
 * ...
 * @author YellowAfterlife
 */
class YyLoader {
	static var nextYypContent:String = null;
	
	/** Only to be used during indexing */
	static var folderMap:Dictionary<TreeViewDir> = null;
	
	static var itemsToInsert:Array<{item:TreeViewElement,dir:TreeViewDir}> = null;
	
	public static inline function isV23(yypContent:String) {
		return yypContent.contains('"resourceType": "GMProject"');
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
			yy.v22.YyLoaderV22.run(project, YyJson.parse(yyProjectTxt));
			return;
		}
		project.hasGMLive = yyProjectTxt.contains('"path":"scripts/GMLive/GMLive.yy"');
		var yyProject:YyProject = YyJsonParser.parse(yyProjectTxt);
		//
		var folderMap = new Dictionary<TreeViewDir>();
		itemsToInsert = [];
		YyLoader.folderMap = folderMap;
		var folderPairs = [];
		for (folder in yyProject.Folders) {
			//
			var folderPath = folder.folderPath;
			if (folderPath.endsWith(".yy")) {
				folderPath = folderPath.substring(0, folderPath.length - 3);
			}
			//
			var folderDir = TreeView.makeAssetDir(folder.name, folderPath + "/", "mixed");
			folderDir.yyOrder = folder.order;
			folderMap[folderPath] = folderDir;
			folderPairs.push({
				dir: folderDir,
				path: folderPath,
			});
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
		topLevel.setAttribute(TreeView.attrRel, project.name);
		TreeView.element.appendChild(topLevel);
		folderMap["folders"] = topLevel;
		//
		for (pair in folderPairs) {
			var folderPath = pair.path;
			var lastSlash = folderPath.lastIndexOf("/");
			var parentPath = folderPath.substring(0, lastSlash);
			var parentDir = folderMap[parentPath];
			if (parentDir == null) {
				Main.console.log("Folder without parent", folderPath);
				continue;
			}
			TreeView.insertSorted(parentDir, pair.dir);
		}
		if (true) {
			var ccs = TreeView.makeAssetItem("roomCreationCodes",
				project.name, project.path, "roomccs");
			ccs.removeAttribute(TreeView.attrThumb);
			ccs.yyOpenAs = KYyRoomCCs.inst;
			ccs.yyOrder = -1;
			var ccsPar:TreeViewDir = JsTools.orx(
				folderMap["folders/Rooms"],
				folderMap["folders/rooms"],
				topLevel
			);
			ccsPar.treeItems.appendChild(ccs);
		}
		if (project.existsSync("#import")) {
			var idir = TreeView.makeAssetDir("Imports", "#import/", "file");
			raw.RawLoader.loadDirRec(project, idir.treeItems, "#import");
			topLevel.treeItems.appendChild(idir);
		}
		if (project.existsSync("datafiles")) {
			var idir = TreeView.makeAssetDir("Included Files", "datafiles/", "file");
			raw.RawLoader.loadDirRec(project, idir.treeItems, "datafiles");
			topLevel.treeItems.appendChild(idir);
		}
		// restoreOpen runs in Project:reload
		project.yyObjectNames = new Dictionary();
		project.yyObjectGUIDs = new Dictionary();
		project.yyResources = new Dictionary();
		project.yyResourceGUIDs = new Dictionary();
		project.yySpriteURLs = new Dictionary();
		project.yyResourceTypes = new Dictionary();
		project.yyOrder = new Dictionary();
		for (resource in yyProject.resources) {
			var resPath = resource.id.path;
			var resName = resource.id.name;
			project.yyOrder[resName] = resource.order;
			// get rid of this mess later
			project.yyResources[resName] = resource;
			project.yyResourceGUIDs[resName] = cast resName;
			//
			if (resPath.startsWith("objects/")) {
				project.yyObjectNames[resName] = resName;
				project.yyObjectGUIDs[resName] = cast resName;
			}
		}
		//
		for (resource in yyProject.resources) {
			GmlSeeker.run(resource.id.path, resource.id.name, KYyUnknown.inst);
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
