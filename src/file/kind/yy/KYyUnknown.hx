package file.kind.yy;
import ace.extern.AceAutoCompleteItem;
import gml.GmlAPI;
import gml.Project;
import gml.file.GmlFile;
import haxe.io.Path;
import js.html.DivElement;
import js.html.Console;
import js.lib.RegExp;
import ui.treeview.TreeView;
import yy.*;
using tools.NativeString;

/**
 * We don't know what this is but we'll find out
 * Indexing phase only
 * @author YellowAfterlife
 */
class KYyUnknown extends FileKind {
	public static var inst:KYyUnknown = new KYyUnknown();
	
	static var rxParentPath:RegExp = new RegExp(
		'\n  "parent":\\s*\\{'
		+ '[^}]*"path":\\s*"([^"]+?)(\\.yy)?"'
	);
	static var rxName = new RegExp('\n  "name": "([^"]+)');
	static var rxResourceType = new RegExp('\n  "resourceType": "([^"]+)');
	override public function index(path:String, content:String, main:String, sync:Bool):Bool {
		var project = Project.current;
		var full = project.fullPath(path);
		//
		var resource:YyResource = null;
		var parentPath:String = {
			var mt = rxParentPath.exec(content);
			if (mt == null) {
				resource = YyJson.parse(content);
				resource.parent.path;
			} else mt[1];
		}
		//
		var resType:String;
		if (resource == null) {
			var mt = rxResourceType.exec(content);
			if (mt == null) {
				resource = YyJson.parse(content);
				resType = resource.resourceType;
			} else resType = mt[1];
		} else resType = resource.resourceType;
		//
		var detect = KYy.inst.detect(path, resource != null ? resource : content);
		//
		if (parentPath.endsWith(".yy")) {
			parentPath = parentPath.substring(0, parentPath.length - 3);
		}
		//
		var name:String;
		if (resource == null) {
			var mt = rxName.exec(content);
			if (mt == null) {
				resource = YyJson.parse(content);
				name = resource.name;
			} else name = mt[1];
		} else name = resource.name;
		project.yyResourceTypes[name] = resType;
		//
		var dir = @:privateAccess YyLoader.folderMap[parentPath];
		if (dir == null) dir = cast TreeView.find(false, { rel: parentPath });
		//
		if (dir != null) {
			var makeEl = true;
			var kind = resType.substring(2).toLowerCase();
			switch (resType) {
				case "GMSprite", "GMTileSet", "GMSound", "GMPath",
					"GMScript", "GMShader", "GMFont", "GMTimeline",
					"GMObject", "GMRoom", "GMAnimCurve"
				: { // assets
					var aceKind = "asset." + kind;
					GmlAPI.gmlKind.set(name, aceKind);
					GmlAPI.gmlLookupItems.push({ value:name, meta:aceKind });
					if (resType != "GMScript") {
						// since 2.3 scripts contain function definitions,
						// why would we care about the script resource itself?
						var next = new AceAutoCompleteItem(name, kind);
						GmlAPI.gmlComp.push(next);
						GmlAPI.gmlAssetComp.set(name, next);
					}
				};
				case "GMNotes": { // not assets, but lookup is allowed
					var aceKind = "asset." + kind;
					GmlAPI.gmlLookupItems.push({ value:name, meta:aceKind });
				};
			}
			// don't touch the relative YY path, rename operations rely on it
			switch (resType) {
				case "GMScript": {
					full = Path.withExtension(full, "gml");
					content = electron.FileWrap.readTextFileSync(full);
				};
				case "GMNotes": {
					full = Path.withExtension(full, "txt");
					if (electron.FileWrap.existsSync(full)) {
						content = electron.FileWrap.readTextFileSync(full);
					} else content = "";
					detect.kind = file.kind.misc.KPlain.inst;
				};
				case "GMExtension": makeEl = false;
			}
			if (makeEl) {
				var item = TreeView.makeAssetItem(name, path, full, kind);
				item.yyOrder = Project.current.yyOrder.defget(name, 0);
				item.yyOpenAs = detect.kind;
				@:privateAccess YyLoader.itemsToInsert.push({
					item: item,
					dir: dir
				});
				var relPath = project.relPath(path);
				if (relPath != null) YyLoader.applyAssetColour(item, relPath);
				//TreeView.insertSorted(dir, item);
				switch (resType) {
					case "GMSprite": TreeView.setThumbSprite(full, name, item);
				}
			}
		} else Console.error('`$path` has missing parent `$parentPath`');
		return detect.kind.index(full, content, main, sync);
	}
}
