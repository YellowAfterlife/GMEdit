package ui.treeview;
import electron.Dialog;
import gml.Project;
import electron.Menu;
import haxe.io.Path;
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
		//
		var isDir = TreeView.isDirectory(el);
		var filter = (isDir ? el : par.parentElement).getAttribute(TreeView.attrFilter);
		//
		var root = TreeView.element;
		var chain = [];
		while (par != null && par != root) {
			var d = par.getAttribute(TreeView.attrLabel);
			if (d != null) chain.unshift(d);
			par = par.parentElement;
		}
		//
		var name = el.getAttribute(TreeView.attrIdent);
		if (name == null) name = el.getAttribute(TreeView.attrLabel);
		//
		return {
			isDir: isDir,
			chain: chain,
			last: name,
			prefix: prefix,
			filter: filter,
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
		if (v != gml.GmlVersion.none) {
			var supported:Bool = true;
			if (v.config.projectModeId == 1) {
				supported = switch (prefix) {
					case "scripts/": true;
					case "objects/": true;
					default: false;
				};
			}
			for (q in items.manipOuter) {
				q.visible = true;
				q.enabled = supported;
			}
			var nonRoot = target.getAttribute(TreeView.attrRel).toLowerCase() != prefix;
			for (q in items.manipNonRoot) q.enabled = supported && nonRoot;
			for (q in items.manipDirOnly) q.enabled = supported && dir;
		} else {
			for (q in items.manipOuter) q.visible = false;
		}
	}
	//
	public static function createImplTV(q:TreeViewItemCreate) {
		var name = q.name;
		var nrel = q.tvDir.getAttribute(TreeView.attrRel) + name;
		var ntv:Element;
		if (q.mkdir) {
			ntv = TreeView.makeAssetDir(name, nrel + "/", q.kind);
			ntv.classList.add(TreeView.clOpen);
		} else {
			var pj = q.pj;
			if (pj == null) pj = Project.current;
			var nfull = pj.fullPath(q.npath);
			ntv = TreeView.makeAssetItem(name, nrel, nfull, q.kind);
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
			case -2: {
				dir.treeItems.insertBefore(ntv, dir.treeItems.lastElementChild);
				if (q.showInTree != false) dir.classList.add(TreeView.clOpen);
			};
			default: {
				dir.treeItems.appendChild(ntv);
				if (q.showInTree != false) dir.classList.add(TreeView.clOpen);
			};
		}
		return ntv;
	}
	//
	static function validate(s:String, tvDir:TreeViewDir, asDir:Bool, filter:String) {
		if (asDir || filter == "file") {
			for (c in tvDir.treeItems.children) {
				if (c.getAttribute(TreeView.attrLabel) == s) {
					Dialog.showAlert("Group already exists!");
					return false;
				}
			}
			if (filter == "file") {
				if ((new RegExp("[\\/*?\"<>|]")).test(s)) {
					Dialog.showAlert("Not a valid file name");
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
	
	/**
	 * @param	mkdir	Make a directory (true) or file (false)
	 * @param	order	-1: before, 1: after, 0: inside, -2: inside but prefer non-last
	 * @param	  dir	Treeview directory to work with
	 * @param	 name	Name of new item
	 * @return	TVIC if successful, null if not
	 */
	public static function createImplBoth(mkdir:Bool, order:Int, dir:Element, name:String, ?preproc:TreeViewItemCreate->TreeViewItemCreate):TreeViewItemCreate {
		var s = name;
		var d = getItemData(dir);
		//
		var tvDir:TreeViewDir = cast (order != 0 ? dir.parentElement.parentElement : dir);
		if (!validate(s, tvDir, mkdir, d.filter)) return null;
		//
		var args:TreeViewItemCreate = {
			prefix: d.prefix,
			plural: d.plural,
			single: d.single,
			tvDir: tvDir,
			tvRef: dir,
			chain: d.chain,
			last: d.last,
			name: s,
			kind: d.filter,
			order: order,
			mkdir: mkdir,
		};
		//
		if (preproc != null) {
			args = preproc(args);
			if (args == null) return null;
		}
		//
		if (d.filter == "file") {
			try {
				var full = Path.join([tvDir.getAttribute(TreeView.attrRel), s]);
				if (mkdir) {
					Project.current.mkdirSync(full);
				} else {
					Project.current.writeTextFileSync(full, "");
				}
				createImplTV(args);
				return args;
			} catch (x:Dynamic) {
				Dialog.showError("Couldn't create the file: " + x);
				return null;
			}
		}
		var vi = Project.current.version.config.projectModeId;
		switch (vi) {
			case 1: gmx.GmxManip.add(args);
			case 2: yy.YyManip.add(args);
			default: Dialog.showAlert("Can't create an item for this version!"); return null;
		}
		return args;
	}
	public static function createImpl(mkdir:Bool, order:Int) {
		var dir = target;
		Dialog.showPrompt("Name?", "", function(s) {
			if (s == "" || s == null) return;
			createImplBoth(mkdir, order, dir, s);
		});
	}
	//
	static function removeImpl() {
		var d = getItemData(target);
		if (!Dialog.showConfirmWarn("Are you sure you want to delete " + d.last + "?"
			+ "\nThis cannot be undone!"
		)) return;
		if (d.filter == "file") {
			try {
				var path0 = target.getAttribute(TreeView.attrRel);
				if (d.isDir) {
					Project.current.rmdirSync(path0);
				} else {
					Project.current.unlinkSync(path0);
				}
				target.parentElement.removeChild(target);
			} catch (x:Dynamic) {
				Dialog.showError("Couldn't remove item: " + x);
			}
			return;
		}
		var args:TreeViewItemBase = {
			prefix: d.prefix,
			plural: d.plural,
			single: d.single,
			chain: d.chain,
			last: d.last,
			tvDir: cast target.parentElement.parentElement,
			tvRef: target,
		};
		var vi = Project.current.version.config.projectModeId;
		switch (vi) {
			case 1: gmx.GmxManip.remove(args);
			case 2: yy.YyManip.remove(args);
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
			if (!validate(s, tvDir, dir, d.filter)) return;
			if (d.filter == "file") {
				try {
					var path0 = target.getAttribute(TreeView.attrRel);
					var path1 = Path.join([Path.directory(path0), s]);
					Project.current.renameSync(path0, path1);
					if (d.isDir) Project.current.reload();
				} catch (x:Dynamic) {
					Dialog.showError("Couldn't rename item: " + x);
				}
				return;
			}
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
			var vi = Project.current.version.config.projectModeId;
			switch (vi) {
				case 1: gmx.GmxManip.rename(args);
				case 2: yy.YyManip.rename(args);
				default: Dialog.showAlert("Can't rename an item for this version!");
			}
		});
	}
	//
	static function initCreateMenu() {
		var createMenu = new Menu();
		for (kind in 0 ... 2) {
			var si = kind > 0 ? "group" : "item";
			if (kind > 0) createMenu.appendSep("sep-" + si);
			var s = kind > 0 ? "Group" : "Item";
			items.manipNonRoot.push(addLink(createMenu, si+"-before", s + " before", function() {
				createImpl(kind > 0, -1);
			}));
			items.manipDirOnly.push(addLink(createMenu, si+"-inside", s + " inside", function() {
				createImpl(kind > 0, 0);
			}));
			items.manipNonRoot.push(addLink(createMenu, si+"-after", s + " after", function() {
				createImpl(kind > 0, 1);
			}));
		}
		var createItem = new MenuItem({
			id: "sub-create",
			label: "Create",
			type: Sub,
			submenu: createMenu
		});
		var removeItem = new MenuItem({
			id: "remove",
			label: "Remove",
			click: removeImpl
		});
		var renameItem = new MenuItem({
			id: "rename",
			label: "Rename",
			click: renameImpl
		});
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
	/** Project reference, defaults to Project.current */
	?pj:Project,
	/** if set, project JSON should be modified instead of reading-flushing */
	?py:yy.YyProject,
	/** if set, new resource is inserted before this one */
	?pyBefore:yy.YyProjectResource,
	/** filled out during call */
	?outGUID:yy.YyGUID,
	/** whether to open the freshly made thing (defaults to true) */
	?openFile:Bool,
	/** whether to reveal the freshly made thing in treeview */
	?showInTree:Bool,
};
typedef TreeViewItemCreate = {
	>TreeViewItemBase,
	name:String,
	kind:String,
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
