package ui.treeview;
import electron.Dialog;
import gml.Project;
import electron.Menu;
import js.lib.RegExp;
import js.html.Element;
import ui.treeview.TreeViewMenus.items;
import ui.treeview.TreeViewMenus.add;
import ui.treeview.TreeViewMenus.addLink;
import ui.treeview.TreeViewMenus.target;
import ui.treeview.TreeView;

/**
 * ...
 * @author YellowAfterlife
 */
class TreeViewItemMenus {
	static var prefix:String;
	public static function getItemData(el:Element) {
		var par = el.parentElement;
		var root = TreeView.element;
		var chain = [];
		while (par != null && par != root) {
			var d = par.getAttribute(TreeView.attrLabel);
			if (d != null) chain.unshift(d);
			par = par.parentElement;
		}
		var name = el.getAttribute(TreeView.attrIdent);
		if (name == null) name = el.getAttribute(TreeView.attrLabel);
		return {
			chain: chain,
			last: name,
			prefix: prefix,
			plural: prefix.substring(0, prefix.length - 1),
			single: prefix.substring(0, prefix.length - 2),
		};
	}
	public static function updatePrefix(par:Element) {
		var root = TreeView.element;
		prefix = "unknown/";
		while (par != null && par != root) {
			if (par.classList.contains(TreeView.clDir)) {
				prefix = par.getAttribute(TreeView.attrRel);
			}
			par = par.parentElement;
		}
		prefix = prefix.toLowerCase();
	}
	static function updateCreateMenu(dir:Bool) {
		updatePrefix(target);
		var v = Project.current.version;
		switch (v) {
			case v1 | v2: {
				var supported = switch (prefix) {
					case "scripts/": true;
					default: v == v2;
				};
				for (q in items.manipOuter) {
					q.visible = true;
					q.enabled = supported;
				}
				var nonRoot = target.getAttribute(TreeView.attrRel).toLowerCase() != prefix;
				for (q in items.manipNonRoot) q.enabled = supported && nonRoot;
				for (q in items.manipDirOnly) q.enabled = supported && dir;
			};
			default: {
				for (q in items.manipOuter) q.visible = false;
			}
		}
	}
	//
	public static function createImplTV(q:TreeViewItemCreate) {
		var name = q.name;
		var nrel = q.tvDir.getAttribute(TreeView.attrRel) + name;
		var ntv:Element;
		if (q.mkdir) {
			ntv = TreeView.makeAssetDir(name, nrel + "/");
			ntv.classList.add(TreeView.clOpen);
		} else {
			var nfull = q.pj.fullPath(q.npath);
			ntv = TreeView.makeAssetItem(name, nrel, nfull, 'script');
		}
		var dir = q.tvDir;
		var ref = q.tvRef;
		switch (q.order) {
			case -1: {
				dir.treeItems.insertBefore(ntv, ref);
			};
			case 1: {
				var after = ref.nextElementSibling;
				if (after != null) {
					dir.treeItems.insertBefore(ntv, after);
				} else dir.treeItems.appendChild(ntv);
			};
			default: {
				dir.treeItems.appendChild(ntv);
				dir.classList.add(TreeView.clOpen);
			};
		}
		return ntv;
	}
	static function validate(s:String, tvDir:TreeViewDir, asDir:Bool) {
		if (asDir) {
			for (c in tvDir.treeItems.children) {
				if (c.getAttribute(TreeView.attrLabel) == s) {
					Dialog.showAlert("Group already exists!");
					return false;
				}
			}
		} else {
			if (!(new RegExp("^[a-zA-Z_]\\w*$")).test(s)) {
				Dialog.showAlert("Name contains illegal characters!");
				return false;
			}
			if (TreeView.find(true, {ident:s}) != null) {
				Dialog.showAlert("Item already exists!");
				return false;
			}
		}
		return true;
	}
	static function createImpl(z:Bool, order:Int) {
		var d = getItemData(target);
		Dialog.showPrompt("Name?", "", function(s:String) {
			if (s == "" || s == null) return;
			//
			var tvDir:TreeViewDir = cast (order != 0 ? target.parentElement.parentElement : target);
			if (!validate(s, tvDir, z)) return;
			var args:TreeViewItemCreate = {
				prefix: d.prefix,
				plural: d.plural,
				single: d.single,
				tvDir: tvDir,
				tvRef: target,
				chain: d.chain,
				last: d.last,
				name: s,
				order: order,
				mkdir: z,
			};
			switch (Project.current.version) {
				case v1: gmx.GmxManip.add(args);
				case v2: yy.YyManip.add(args);
				default: Dialog.showAlert("Can't create an item for this version!");
			}
		});
	}
	//
	static function removeImpl() {
		var d = getItemData(target);
		if (!Dialog.showConfirm("Are you sure you want to delete " + d.last + "?")) return;
		var args:TreeViewItemBase = {
			prefix: d.prefix,
			plural: d.plural,
			single: d.single,
			chain: d.chain,
			last: d.last,
			tvDir: cast target.parentElement.parentElement,
			tvRef: target,
		};
		switch (Project.current.version) {
			case v1: gmx.GmxManip.remove(args);
			case v2: yy.YyManip.remove(args);
			default: Dialog.showAlert("Can't remove an item for this version!");
		}
	}
	//
	public static function renameImpl_1(q:TreeViewItemRename) {
		
	}
	static function renameImpl() {
		var d = getItemData(target);
		Dialog.showPrompt("New name?", d.last, function(s:String) {
			if (s == d.last || s == "" || s == null) return;
			var dir = target.classList.contains(TreeView.clDir);
			var tvDir:TreeViewDir = cast target.parentElement.parentElement;
			if (!validate(s, tvDir, dir)) return;
			var args:TreeViewItemRename = {
				prefix: d.prefix,
				plural: d.plural,
				single: d.single,
				chain: d.chain,
				last: d.last,
				tvDir: tvDir,
				tvRef: target,
				name: s,
			};
			switch (Project.current.version) {
				case v1: gmx.GmxManip.rename(args);
				case v2: yy.YyManip.rename(args);
				default: Dialog.showAlert("Can't rename an item for this version!");
			}
		});
	}
	//
	static function initCreateMenu() {
		var createMenu = new Menu();
		for (kind in 0 ... 2) {
			if (kind > 0) createMenu.appendSep();
			var s = kind > 0 ? "Group" : "Item";
			items.manipNonRoot.push(addLink(createMenu, s + " before", function() {
				createImpl(kind > 0, -1);
			}));
			items.manipDirOnly.push(addLink(createMenu, s + " inside", function() {
				createImpl(kind > 0, 0);
			}));
			items.manipNonRoot.push(addLink(createMenu, s + " after", function() {
				createImpl(kind > 0, 1);
			}));
		}
		var createItem = new MenuItem({ label: "Create", type: Sub, submenu: createMenu });
		var removeItem = new MenuItem({ label: "Remove", click: removeImpl });
		var renameItem = new MenuItem({ label: "Rename", click: renameImpl });
		items.manipCreate = createItem;
		// new MenuItem({type:Sep}), 
		items.manipOuter = [createItem, removeItem, renameItem];
		items.manipNonRoot.push(removeItem);
	}
	public static function update(dir:Bool) {
		updateCreateMenu(dir);
	}
	public static function init() {
		initCreateMenu();
	}
}
typedef TreeViewItemBase = {
	prefix:String,
	single:String,
	plural:String,
	tvDir:TreeViewDir,
	tvRef:Element,
	chain:Array<String>, last:String,
	?pj:Project,
	/** if set, project JSON should be modified instead of reading-flushing */
	?py:yy.YyProject,
	/** if set, new resource is inserted before this one */
	?pyBefore:yy.YyProjectResource,
	/** filled out during call */
	?outGUID:yy.YyGUID,
	/** whether to open the freshly made thing (defaults to true) */
	?openFile:Bool
};
typedef TreeViewItemCreate = {
	>TreeViewItemBase,
	name:String,
	order:Int, mkdir:Bool,
	?npath:String,
};
typedef TreeViewItemRename = {
	>TreeViewItemBase,
	name:String,
}
typedef TreeViewItemMove = {
	>TreeViewItemBase,
	srcChain:Array<String>,
	srcLast:String,
	srcDir:TreeViewDir,
	srcRef:Element,
	order:Int,
}
