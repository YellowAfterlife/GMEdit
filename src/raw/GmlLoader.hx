package raw;
import electron.FileSystem;
import gml.Project;
import haxe.io.Path;
import js.html.Element;
import ui.TreeView;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLoader {
	public static function run(project:Project) {
		function loadrec(out:Element, dirFull:String, dirRel:String):Void {
			var rd = [], rf = [];
			for (item in FileSystem.readdirSync(dirFull)) {
				var full = Path.join([dirFull, item]);
				var rel = Path.join([dirRel, item]);
				var stat = FileSystem.statSync(full);
				if (stat.isDirectory()) {
					var nd = TreeView.makeDir(item, rel);
					loadrec(nd.treeItems, full, rel);
					rd.push(nd);
				} else rf.push(TreeView.makeItem(item, rel, full, "module"));
			}
			for (el in rd) out.appendChild(el);
			for (el in rf) out.appendChild(el);
		}
		TreeView.clear();
		loadrec(TreeView.element, Path.directory(project.path), "");
	}
}
