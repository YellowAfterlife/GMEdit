package file.kind.yy;
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
		var dir = TreeView.find(false, {
			rel: parentPath
		});
		var full = gml.Project.current.fullPath(path);
		if (dir != null) {
			var makeEl = true;
			switch (resource.resourceType) {
				case "GMScript": {
					full = haxe.io.Path.withoutExtension(full) + ".gml";
					content = electron.FileWrap.readTextFileSync(full);
				};
				case "GMExtension": makeEl = false;
			}
			if (makeEl) {
				var kind = resource.resourceType.substring(2).toLowerCase();
				var item = TreeView.makeAssetItem(resource.name, path, full, kind);
				item.yyOpenAs = detect.kind;
				TreeView.insertSorted(cast dir, item);
			}
		} else Main.console.error('`$path` has missing parent `$parentPath`');
		return detect.kind.index(full, content, main);
	}
}
