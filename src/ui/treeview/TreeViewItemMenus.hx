package ui.treeview;
import electron.Dialog;
import gml.Project;
import electron.Menu;
import js.RegExp;
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
	static function getItemData(incSelf:Bool) {
		var par = incSelf ? target : target.parentElement;
		var root = TreeView.element;
		var chain = [];
		while (par != null && par != root) {
			var d = par.getAttribute(TreeView.attrLabel);
			if (d != null) chain.unshift(d);
			par = par.parentElement;
		}
		var name = target.getAttribute(TreeView.attrIdent);
		if (name == null) name = target.getAttribute(TreeView.attrLabel);
		return {
			chain: chain,
			last: name,
		};
	}
	static function updateCreateMenu(dir:Bool) {
		var par = target;
		var root = TreeView.element;
		prefix = "unknown/";
		while (par != null && par != root) {
			if (par.classList.contains(TreeView.clDir)) {
				prefix = par.getAttribute(TreeView.attrRel);
			}
			par = par.parentElement;
		}
		prefix = prefix.toLowerCase();
		switch (Project.current.version) {
			case v1 | v2: {
				for (q in items.manipOuter) q.visible = true;
				items.manipCreate.enabled = switch (prefix) {
					case "scripts/": true;
					default: false;
				};
				var nonRoot = target.getAttribute(TreeView.attrRel).toLowerCase() != prefix;
				for (q in items.manipNonRoot) q.enabled = nonRoot;
				for (q in items.manipDirOnly) q.enabled = dir;
			};
			default: {
				for (q in items.manipOuter) q.visible = false;
			}
		}
	}
	public static function createImplTV(q:TreeViewItemCreate) {
		var name = q.name;
		var nrel = q.tvDir.getAttribute(TreeView.attrRel) + name;
		var ntv:Element;
		if (q.mkdir) {
			ntv = TreeView.makeDir(name, nrel + "/");
		} else {
			var nfull = q.pj.fullPath(q.npath);
			ntv = TreeView.makeItem(name, nrel, nfull, 'script');
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
	static function createImpl(z:Bool, order:Int) {
		var d = getItemData(false);
		Dialog.showPrompt("Name?", "", function(s:String) {
			if (s == "" || s == null) return;
			//
			var tvDir:TreeViewDir = cast (order != 0 ? target.parentElement.parentElement : target);
			if (z) {
				for (c in tvDir.treeItems.children) {
					if (c.getAttribute(TreeView.attrLabel) == s) {
						Dialog.showAlert("Group already exists!");
						return;
					}
				}
			} else {
				if (!(new RegExp("^\\w+$")).test(s)) {
					Dialog.showAlert("Name contains illegal characters!");
					return;
				}
				if (TreeView.find(true, {ident:s}) != null) {
					Dialog.showAlert("Item already exists!");
					return;
				}
			}
			var args:TreeViewItemCreate = {
				prefix: prefix,
				plural: prefix.substring(0, prefix.length - 1),
				single: prefix.substring(0, prefix.length - 2),
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
	static function removeImpl() {
		var d = getItemData(false);
		if (!Dialog.showConfirm("Are you sure you want to delete " + d.last + "?")) return;
		var args:TreeViewItemBase = {
			prefix: prefix,
			plural: prefix.substring(0, prefix.length - 1),
			single: prefix.substring(0, prefix.length - 2),
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
	static function initCreateMenu() {
		var createMenu = new Menu();
		for (kind in 0 ... 2) {
			var sub = new Menu();
			items.manipNonRoot.push(addLink(sub, "Before this", function() {
				createImpl(kind > 0, -1);
			}));
			items.manipDirOnly.push(addLink(sub, "Inside this", function() {
				createImpl(kind > 0, 0);
			}));
			items.manipNonRoot.push(addLink(sub, "After this", function() {
				createImpl(kind > 0, 1);
			}));
			add(createMenu, {
				label: kind > 0 ? "Group" : "Item",
				type: Sub,
				submenu: sub
			});
		}
		var createItem = new MenuItem({ label: "Create", type: Sub, submenu: createMenu });
		var removeItem = new MenuItem({ label: "Remove", click: removeImpl });
		items.manipCreate = createItem;
		items.manipOuter = [createItem, removeItem];
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
};
typedef TreeViewItemCreate = {
	>TreeViewItemBase,
	name:String,
	order:Int, mkdir:Bool,
	?npath:String,
};
