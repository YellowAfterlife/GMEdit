package file.kind.yy;
import ace.extern.AceAutoCompleteItem;
import gml.GmlAPI;
import gml.Project;
import gml.file.GmlFile;
import js.html.DivElement;
import ui.treeview.TreeView;
using tools.NativeString;

/**
 * We don't know what this is but we'll find out
 * Indexing phase only
 * @author YellowAfterlife
 */
class KYyUnknown extends FileKind {
	public static var inst:KYyUnknown = new KYyUnknown();
	
	override public function index(path:String, content:String, main:String):Bool {
		var resource:yy.YyResource = yy.YyJson.parse(content);
		var detect = KYy.inst.detect(path, resource);
		//
		var parentPath = resource.parent.path;
		if (parentPath.endsWith(".yy")) {
			parentPath = parentPath.substring(0, parentPath.length - 3);
		}
		//
		var resType = resource.resourceType;
		Project.current.yyResourceTypes[resource.name] = resType;
		//
		var dir = TreeView.find(false, {
			rel: parentPath
		});
		var full = gml.Project.current.fullPath(path);
		if (dir != null) {
			var makeEl = true;
			var kind = resType.substring(2).toLowerCase();
			var name = resource.name;
			switch (resType) {
				case "GMSprite", "GMTileSet", "GMSound", "GMPath",
					"GMScript", "GMShader", "GMFont", "GMTimeline",
					"GMObject", "GMRoom"
				: {
					GmlAPI.gmlKind.set(name, "asset." + kind);
					GmlAPI.gmlLookupText += name + "\n";
					var next = new AceAutoCompleteItem(name, kind);
					GmlAPI.gmlComp.push(next);
					GmlAPI.gmlAssetComp.set(name, next);
				};
			}
			switch (resType) {
				case "GMScript": {
					full = haxe.io.Path.withoutExtension(full) + ".gml";
					content = electron.FileWrap.readTextFileSync(full);
				};
				case "GMExtension": makeEl = false;
			}
			if (makeEl) {
				var item = TreeView.makeAssetItem(name, path, full, kind);
				item.yyOpenAs = detect.kind;
				TreeView.insertSorted(cast dir, item);
			}
		} else Main.console.error('`$path` has missing parent `$parentPath`');
		return detect.kind.index(full, content, main);
	}
}
