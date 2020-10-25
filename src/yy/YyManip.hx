package yy;
import ace.extern.AceAutoCompleteItem;
import electron.Dialog;
import file.FileKind;
import file.kind.gml.KGmlScript;
import file.kind.yy.*;
import gml.GmlAPI;
import gml.Project;
import haxe.ds.Map;
import haxe.io.Path;
import js.lib.RegExp;
import js.html.Element;
import tools.NativeString;
import ui.ChromeTabs;
import ui.treeview.TreeView;
import ui.treeview.TreeViewItemMenus;
import ui.treeview.TreeViewElement;
import yy.YyProject;
import yy.YyProjectResource;
import yy.*;
using tools.HtmlTools;
using tools.NativeArray;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class YyManip {
	static function prepare(q:TreeViewItemBase) {
		var pj = Project.current;
		var py = q.py;
		if (py == null) py = pj.readYyFileSync(pj.name);
		return { pj: pj, py: py };
	}
	
	/**
	 * Changes parent of a resource, cheaply or properly
	 * @param	pj
	 * @param	yyPath      "rooms/Room1.yy"
	 * @param	newParName  "Sub"
	 * @param	newParPath  "folders/Rooms/Sub.yy"
	 */
	static function changeParent(pj:Project, yyPath:String, newParName:String, newParPath:String):Void {
		// an easy way out: if the file is well-formatted, we can patch it as text
		// and then we will not have to deal with preserving the field order/formatting
		var yyText = pj.readTextFileSync(yyPath);
		var isDone = false;
		yyText = yyText.replaceExt(__changeParent_rx, function(_, s1, _, s2, _, s3) {
			isDone = true;
			return s1 + newParName + s2 + newParPath + s3;
		});
		if (isDone) {
			pj.writeTextFileSync(yyPath, yyText);
			return;
		}
		// guess we have to actually parse the JSON and such:
		var yy:YyResource = YyJson.parse(yyText, true);
		yy.parent.name = newParName;
		yy.parent.path = newParPath;
		pj.writeYyFileSync(yyPath, yy);
	}
	private static var __changeParent_rx = new RegExp(
		'(\n  "parent":\\s*\\{'
		+ '\r?\n    "name":\\s*")(.*?)(",'
		+ '\r?\n    "path":\\s*")(.*?)(")'
	);
	
	static function getProjectItemForTreeEl(py:YyProject, el:TreeViewElement):YyProjectFolderOrResource {
		var path = el.treeRelPath;
		if (el.treeIsDir) {
			path = path.trimIfEndsWith("/") + ".yy";
			return py.Folders.findFirst((f) -> f.folderPath == path);
		} else return py.resources.findFirst((r) -> r.id.path == path);
	}
	
	static function offsetTreeItems(py:YyProject, items:ElementListOf<TreeViewElement>, start:Int, offset:Int):Bool {
		var changed = false;
		for (i in start ... items.length) {
			var el = items[i];
			el.yyOrder += offset;
			var item = getProjectItemForTreeEl(py, el);
			if (item != null) {
				changed = true;
				item.order += offset;
			}
		}
		return changed;
	}
	
	public static function add(args:TreeViewItemCreate) {
		var pdat = prepare(args);
		var pj = pdat.pj, py = pdat.py;
		var name = args.name;
		var parDir = args.tvDir;
		
		// create the resource itself:
		var kind = args.kind;
		var yypItem:YyProjectFolderOrResource;
		var ntv:TreeViewElement;
		var yyResource:YyResource = null;
		var yyResourceText:String = null;
		var yyPath:String = null;
		var yyFullPath:String = null;
		var indexText:String = null;
		if (args.mkdir) {
			var pre = (parDir.treeIsRoot ? "folders/" : parDir.treeRelPath) + name;
			var folder:YyProjectFolder = {
				folderPath: pre + ".yy",
				order: -1,
				resourceVersion: "1.0",
				name: name,
				tags: [],
				resourceType: "GMFolder",
			};
			py.Folders.push(folder);
			yypItem = folder;
			ntv = TreeView.makeAssetDir(name, pre + "/", "mixed");
		}
		else {
			var kindRoot = kind + "s";
			var dir = '$kindRoot/$name';
			var pre = '$dir/$name';
			yyPath = pre + ".yy";
			yyFullPath = pj.fullPath(yyPath);
			args.npath = yyPath;
			if (!pj.existsSync(dir)) pj.mkdirSync(dir);
			var yyParent:YyResourceRef = {
				"name": parDir.treeLabel,
				"path": parDir.treeFolderPath23,
			};
			switch (kind) {
				case "script": {
					var scr:YyScript = {
						"isDnD": false,
						"isCompatibility": false,
						"parent": yyParent,
						"resourceVersion": "1.0",
						"name": name,
						"tags": [],
						"resourceType": "GMScript",
					};
					yyResource = scr;
					//
					var gml = args.gmlCode;
					if (gml == null) gml = 'function $name() {}';
					indexText = gml;
					var gmlPath = pre + ".gml";
					args.npath = gmlPath;
					pj.writeTextFileSync(gmlPath, gml);
				};
				case "object": {
					var obj:YyObject = {
						"spriteId": null,
						"solid": false,
						"visible": true,
						"spriteMaskId": null,
						"persistent": false,
						"parentObjectId": null,
						"physicsObject": false,
						"physicsSensor": false,
						"physicsShape": 1,
						"physicsGroup": 1,
						"physicsDensity": 0.5,
						"physicsRestitution": 0.1,
						"physicsLinearDamping": 0.1,
						"physicsAngularDamping": 0.1,
						"physicsFriction": 0.2,
						"physicsStartAwake": true,
						"physicsKinematic": false,
						"physicsShapePoints": [],
						"eventList": [],
						"properties": [],
						"overriddenProperties": [],
						"parent": yyParent,
						"resourceVersion": "1.0",
						"name": name,
						"tags": [],
						"resourceType": "GMObject",
					}; yyResource = obj;
				};
				default: {
					Dialog.showError('No idea how to create type=`$kind`, sorry');
					return false;
				};
			}
			//
			yyResourceText = YyJson.stringify(yyResource, true);
			pj.writeTextFileSync(yyPath, yyResourceText);
			if (indexText == null) indexText = yyResourceText;
			//
			var res:YyProjectResource = {
				id: { name: name, path: pre + ".yy" },
				order: -1,
			};
			py.resources.push(res);
			yypItem = res;
			//
			ntv = TreeView.makeAssetItem(name, yyPath, yyFullPath, kind);
		}
		
		// add the treeview and realign YYP items:
		TreeViewItemMenus.insertImplTV(parDir, args.tvRef, ntv, args.order);
		var parItemEls = parDir.treeItemEls;
		var itemOrder = parItemEls.indexOf(ntv);
		yypItem.order = itemOrder;
		offsetTreeItems(py, parItemEls, itemOrder + 1, 1);
		
		// Update the YYP:
		if (args.py == null) pj.writeYyFileSync(pj.name, py);
		
		// index the new item:
		if (args.mkdir) {
			// OK! It's a folder
		} else switch (kind) {
			case "script": {
				GmlAPI.gmlComp.push(new AceAutoCompleteItem(name, kind));
				GmlAPI.gmlKind.set(name, "asset." + kind);
				GmlAPI.gmlLookup.set(name, { path: yyPath, row: 0 });
				GmlAPI.gmlLookupText += name + "\n";
				var fk:FileKind = switch (kind) {
					case "object": KYyEvents.inst;
					case "shader": null;
					default: KGmlScript.inst;
				}
				var fullPath = pj.fullPath(args.npath);
				if (fk != null) parsers.GmlSeeker.runSync(fullPath, indexText, name, fk);
				if (args.openFile != false) {
					gml.file.GmlFile.open(args.name, fullPath);
				}
			};
		}
		return true;
	}
	public static function remove(q:TreeViewItemBase) {
		return false;
	}
	public static function rename(q:TreeViewItemRename) {
		return false;
	}
	
	public static function move(q:TreeViewItemMove) {
		var pdat = prepare(q);
		var pj = pdat.pj, py = pdat.py;
		//
		function moveDirRec(dirEl:TreeViewDir, path:String) {
			var dirName = Path.withoutDirectory(path);
			var dirPath = path + ".yy";
			// update YYP item:
			var curPath = dirEl.treeRelPath;
			var curYyPath = curPath.trimIfEndsWith("/") + ".yy";
			var yyItem = py.Folders.findFirst((f) -> f.folderPath == curYyPath);
			if (yyItem != null) yyItem.folderPath = dirPath;
			//
			var dirPrefix = path + "/";
			dirEl.treeRelPath = dirPrefix;
			for (el in dirEl.treeItemEls) {
				var elPath = el.treeRelPath;
				if (el.treeIsDir) {
					moveDirRec(el.asTreeDir(), dirPrefix + el.treeLabel);
				} else {
					changeParent(pj, el.treeRelPath, dirName, dirPath);
				}
			}
		}
		
		var dragEl:TreeViewElement = q.srcRef;
		var isDir = dragEl.treeIsDir;
		var dragElPath = dragEl.treeRelPath; // current path
		var dragItem = getProjectItemForTreeEl(py, dragEl);
		var oldDir = q.srcDir;
		//
		var newDir = q.tvDir;
		var newDirPath = newDir.treeRelPath;
		//Main.console.log(q, dragElPath, newDirPath);
		//
		if (oldDir == newDir) {
			// just changing order
		} else if (isDir) {
			var newPath:String;
			if (newDirPath == pj.name) {
				newPath = "folders/" + dragEl.treeLabel;
			} else {
				newPath = newDirPath + dragEl.treeLabel;
			}
			moveDirRec(cast dragEl, newPath);
		} else {
			var newParentName:String, newParentPath:String;
			if (newDirPath == pj.name) {
				newParentName = Path.withoutExtension(pj.name);
				newParentPath = newDirPath;
			} else {
				newParentName = newDir.treeLabel;
				newParentPath = newDirPath.trimIfEndsWith("/") + ".yy";
			}
			changeParent(pj, dragElPath, newParentName, newParentPath);
		}
		
		// shift subsequent items in current container back:
		var oldParItems = q.srcDir.treeItemEls;
		var oldParIndex = oldParItems.indexOf(dragEl);
		offsetTreeItems(py, oldParItems, oldParIndex + 1, -1);
		/*for (i in oldParIndex + 1 ... oldParItems.length) {
			var el = oldParItems[i];
			el.yyOrder -= 1;
			var item = getPyItemForTreeEl(el);
			if (item != null) item.order -= 1;
		}*/
		q.srcDir.treeItems.removeChild(dragEl);
		
		// shift subsequent items in new container forward:
		var newDirItems = newDir.treeItemEls;
		var newDirIndex:Int;
		if (q.order == 0) {
			newDirIndex = newDirItems.length;
		} else {
			newDirIndex = newDirItems.indexOf(cast q.tvRef);
			if (q.order > 0 && newDirIndex >= 0) newDirIndex++;
		}
		dragItem.order = newDirIndex;
		offsetTreeItems(py, newDirItems, newDirIndex, 1);
		/*for (i in newDirIndex ... newDirItems.length) {
			var el = newDirItems[i];
			el.yyOrder += 1;
			var item = getPyItemForTreeEl(el);
			if (item != null) item.order += 1;
		}*/
		newDir.treeItems.insertBefore(dragEl, newDirItems[newDirIndex]);
		
		//
		pj.writeYyFileSync(pj.name, py);
		return true;
	}
	public static function moveTV(q:TreeViewItemMove) {
		q.srcRef.parentElement.removeChild(q.srcRef);
		switch (q.order) {
			case 1: q.tvRef.insertAfterSelf(q.srcRef);
			case -1: q.tvRef.insertBeforeSelf(q.srcRef);
			default: q.tvDir.treeItems.appendChild(q.srcRef);
		}
	}
}
abstract YyProjectFolderOrResource(Dynamic)
from YyProjectFolder from YyProjectResource to YyProjectFolder to YyProjectResource {
	public var order(get, set):Int;
	private inline function get_order():Int {
		return (this:YyProjectFolder).order;
	}
	private inline function set_order(ord:Int):Int {
		return (this:YyProjectFolder).order = ord;
	}
}