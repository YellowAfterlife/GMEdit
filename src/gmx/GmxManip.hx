package gmx;
import electron.Dialog;
import gml.Project;
import js.RegExp;
import js.html.Element;
import ui.treeview.TreeView;
import ui.treeview.TreeViewItemMenus;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxManip {
	static function resolve(q:TreeViewItemBase) {
		if (q.chain.length > 0) {
			q.chain[0] = q.chain[0].toLowerCase();
		} else q.last = q.last.toLowerCase();
		var pj = Project.current;
		q.pj = pj;
		var root = pj.readGmxFileSync(pj.name);
		var plural = q.plural, single = q.single;
		//
		var dir = root;
		for (sp in q.chain) {
			var sub = null;
			for (o in dir.findAll(plural)) {
				if (o.get("name") == sp) {
					sub = o;
					break;
				}
			}
			if (sub == null) {
				Dialog.showAlert("Couldn't find directory " + q.chain.join("/"));
				return null;
			} else dir = sub;
		}
		//
		var ref:SfGmx = null;
		var rxn = new RegExp("^\\w+[/\\\\](\\w+)");
		for (o in dir.children) {
			if (o.name == single) {
				var r = rxn.exec(o.text);
				if (r != null && r[1] == q.last) {
					ref = o; break;
				}
			} else if (o.get("name") == q.last) {
				ref = o; break;
			}
		}
		if (ref == null) {
			Dialog.showAlert("Couldn't find item " + q.last + "!");
			return null;
		}
		return {
			pj: pj,
			root: root,
			plural: plural,
			single: single,
			dir: dir,
			ref: ref,
		};
	}
	public static function add(q:TreeViewItemCreate) {
		var d = resolve(q);
		if (d == null) return false;
		var pj = d.pj;
		var root = d.root;
		var plural = d.plural;
		var single = d.single;
		var dir = d.dir;
		var ref = d.ref;
		//
		var name = q.name;
		var ngmx:SfGmx;
		if (q.mkdir) {
			ngmx = new SfGmx(plural);
			ngmx.set("name", name);
		} else {
			var ntxt:String = switch (single) {
				case "script": plural + "\\" + name + ".gml";
				default: plural + "\\" + name;
			};
			switch (single) {
				case "script": {
					q.npath = '$plural/$name.gml';
					pj.writeTextFileSync(q.npath, '');
				};
			}
			ngmx = new SfGmx(single, ntxt);
		}
		//
		switch (q.order) {
			case -1: {
				dir.children.insert(dir.children.indexOf(ref), ngmx);
			};
			case 1: {
				dir.children.insert(dir.children.indexOf(ref) + 1, ngmx);
			};
			default: {
				ref.children.push(ngmx);
			};
		}
		TreeViewItemMenus.createImplTV(q);
		//
		pj.writeTextFileSync(pj.name, root.toGmxString());
		pj.reload();
		return true;
	}
	public static function remove(q:TreeViewItemBase) {
		var d = resolve(q);
		if (d == null) return false;
		var pj = d.pj;
		var root = d.root;
		var plural = d.plural;
		var single = d.single;
		var dir = d.dir;
		var ref = d.ref;
		//
		function remrec(node:SfGmx):Void {
			if (node.name == single) {
				var dp = node.text;
				switch (single) {
					case "script": {};
					default: dp += '.$single.gmx';
				};
				if (pj.existsSync(dp)) {
					pj.unlinkSync(dp);
				}
			} else {
				for (child in node.children) remrec(child);
			}
		}
		//
		remrec(ref);
		dir.removeChild(ref);
		q.tvDir.treeItems.removeChild(q.tvRef);
		//
		pj.writeTextFileSync(pj.name, root.toGmxString());
		pj.reload();
		return true;
	}
}
