package ui.treeview;
import ui.preferences.PrefData.PrefAssetOrder23;
import gml.file.GmlFile;
import ui.ChromeTabs.ChromeTab;
import electron.Dialog;
import electron.Electron;
import gml.Project;
import electron.Menu;
import haxe.io.Path;
import js.lib.RegExp;
import js.html.Element;
import tools.JsTools;
import ui.treeview.TreeViewMenus.items;
import ui.treeview.TreeViewMenus.add;
import ui.treeview.TreeViewMenus.addLink;
import ui.treeview.TreeViewMenus.target;
import ui.treeview.TreeView;
import ui.treeview.TreeViewElement;
import yy.YyManip;
import yy.v22.YyManipV22;
using tools.NativeString;
import Main.document;

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
	/** Note: doesn't do  */
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
					case "shaders/": true;
					default: false;
				};
			}
			for (q in items.manipOuter) {
				if (q.id == "edit-tags") {
					if (Project.current.isGMS23) {
						var rel = target.getAttribute(TreeView.attrRel);
						q.visible = dir || rel != null && rel.endsWith(".yy");
					} else q.visible = false;
				} else  q.visible = true;
				q.enabled = supported;
			}
			//
			var v23 = Project.current.isGMS23;
			for (item in items.manipCreate.submenu.items) {
				var only23:Bool = (cast item).yyOnlyV23;
				if (only23 != null) item.visible = only23 == v23;
			}
			//
			var nonRoot = target.getAttribute(TreeView.attrRel).toLowerCase() != prefix;
			for (q in items.manipNonRoot) q.enabled = supported && nonRoot;
			for (q in items.manipDirOnly) q.enabled = supported && dir;
			items.manipDuplicate.enabled = supported && (prefix == "scripts/") && !dir;
		} else {
			for (q in items.manipOuter) q.visible = false;
		}
	}
	//
	public static function insertImplTV(dir:TreeViewDir, ref:Element, ntv:TreeViewElement, order:Int, ?showInTree:Bool) {
		switch (order) {
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
				if (showInTree != false) dir.classList.add(TreeView.clOpen);
			};
			default: {
				dir.treeItems.appendChild(ntv);
				if (showInTree != false) dir.classList.add(TreeView.clOpen);
			};
		}
	}
	public static function createImplTV(q:TreeViewItemCreate):TreeViewElement {
		var name = q.name;
		var nrel = q.tvDir.getAttribute(TreeView.attrRel) + name;
		var ntv:TreeViewElement;
		if (q.mkdir) {
			ntv = TreeView.makeAssetDir(name, nrel + "/", q.kind);
			ntv.classList.add(TreeView.clOpen);
		} else {
			var pj = q.pj;
			if (pj == null) pj = Project.current;
			var nfull = pj.fullPath(q.npath);
			ntv = TreeView.makeAssetItem(name, nrel, nfull, q.kind);
		}
		insertImplTV(q.tvDir, q.tvRef, ntv, q.order, q.showInTree);
		return ntv;
	}
	//
	static function validate(s:String, tvDir:TreeViewDir, asDir:Bool, filter:String, kind:String) {
		if (asDir || filter == "file") {
			for (c in tvDir.treeItems.children) {
				if (c.getAttribute(TreeView.attrLabel) == s) {
					Dialog.showError("Group already exists!");
					return false;
				}
			}
			if (filter == "file") {
				if ((new RegExp("[\\/*?\"<>|]")).test(s)) {
					Dialog.showError("Not a valid file name!");
					return false;
				}
			}
		} else {
			if (kind != "note" && !(new RegExp("^[a-zA-Z_]\\w*$")).test(s)) {
				Dialog.showError("Name contains illegal characters!");
				return false;
			}
			if (TreeView.find(true, {ident:s}) != null) {
				Dialog.showError("Item already exists!");
				return false;
			}
		}
		return true;
	}
	
	/**
	 * @param	 kind	What to make ("dir", "auto" to detect from dir, otherwise asset kind)
	 * @param	order	-1: before, 1: after, 0: inside, -2: inside but prefer non-last
	 * @param	  dir	Treeview directory to work with
	 * @param	 name	Name of new item
	 * @return	TVIC if successful, null if not
	 */
	public static function createImplBoth(kind:String, order:Int, dir:Element, name:String, ?preproc:TreeViewItemCreate-> TreeViewItemCreate):TreeViewItemCreate {
		if (Std.is(kind, Bool)) kind = (cast kind:Bool) ? "dir" : "auto";
		var s = name;
		var d = getItemData(dir);
		//
		var mkdir = kind == "dir";
		var tvDir:TreeViewDir = cast (order != 0 ? dir.parentElement.parentElement : dir);
		if (!validate(s, tvDir, mkdir, d.filter, kind)) return null;
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
			kind: (kind != "auto" && !mkdir) ? kind : d.filter,
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
				var newRel = Path.join([tvDir.getAttribute(TreeView.attrRel), s]);
				if (mkdir) {
					Project.current.mkdirSync(newRel);
				} else {
					Project.current.writeTextFileSync(newRel, "");
				}
				args.npath = newRel;
				createImplTV(args);
				return args;
			} catch (x:Dynamic) {
				Dialog.showError("Couldn't create the file: " + x);
				return null;
			}
		}
		var pj = Project.current;
		switch (pj.version.config.projectModeId) {
			#if !gmedit.no_gmx
			case 1: gmx.GmxManip.add(args);
			#end
			case 2: {
				if (pj.yyUsesGUID) {
					YyManipV22.add(args);
				} else YyManip.add(args);
			};
			default: Dialog.showAlert("Can't create an item for this version!"); return null;
		}
		return args;
	}
	public static function createImpl(kind:String, order:Int) {
		var dir = target;

		var targetData = getItemData(target);
		var targetTV:TreeViewItem = cast target;
		var mkdir = kind == "dir";

		var args:TreeViewItemCreate = {
			prefix: targetData.prefix,
			plural: targetData.plural,
			single: targetData.single,
			tvDir: order == 0 ? targetTV.asTreeDir() : targetTV.treeParentDir,
			tvRef: dir,
			chain: targetData.chain,
			last: targetData.last,
			name: "",
			kind: (kind != "auto" && !mkdir) ? kind : targetData.filter,
			order: order,
			mkdir: mkdir,
		};

		// Create a temporary TreeItem that hosts the textbox
		var result = createImplTV(args);
		// Set variables to nothing so we dont accidentally try something
		result.treeRelPath = "";
		result.treeFullPath = "";

		result.showInlineTextbox(function(name) {
			// Remove the temporary item
			result.remove();
			if (name != "") {
				// Insert the real item at the same spot
				createImplBoth(kind, order, dir, name);
			}
		});
	}
	//
	static function removeImpl() {
		var d = getItemData(target);
		//
		var mode:Int = null;
		var msg = "Are you sure you want to delete " + d.last + "?"
			+ "\nThis cannot be undone!";
		if (Project.current.isGMS23 && ( // is an item or contains items
			target.classList.contains(TreeView.clItem)
			|| target.querySelector("." + TreeView.clItem) != null
		)) {
			var exp = "Cleaning up references is experimental and you should be using backups/source control.";
			if (Electron != null) {
				mode = Dialog.showMessageBox({
					//noLink: true,
					message: msg,
					detail: exp,
					buttons: ["Delete", "Delete and clean up references", "Cancel"],
					cancelId: 2,
				});
			} else if (Dialog.showConfirmWarn(msg)) {
				mode = Dialog.showConfirmWarn("Would you also like to clean up references?\n\n" + exp) ? 1 : 0;
			} else mode = 2;
		}
		if (mode == null) mode = Dialog.showConfirmWarn(msg) ? 0 : 2;
		if (mode == 2) return;
		if (target.getAttribute(TreeView.attrKind) == "extfile") {
			if (Project.current.version.config.projectModeId == 2) {
				var tvDir:TreeViewDir = cast target.parentElement.parentElement;
				yy.shared.YyManipExtension.deleteFile(tvDir.treeFullPath, d.last);
				target.parentElement.removeChild(target);
			}
			return;
		}
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
		var args:TreeViewItemRemove = {
			prefix: d.prefix,
			plural: d.plural,
			single: d.single,
			chain: d.chain,
			last: d.last,
			tvDir: cast target.parentElement.parentElement,
			tvRef: target,
			cleanRefs: mode == 1,
		};
		var project = Project.current;
		var vi = project.version.config.projectModeId;
		switch (vi) {
			#if !gmedit.no_gmx
			case 1: gmx.GmxManip.remove(args);
			#end
			case 2: {
				if (project.yyUsesGUID) {
					YyManipV22.remove(args);
				} else YyManip.remove(args);
			};
			default: Dialog.showAlert("Can't remove an item for this version!");
		}
	}
	//
	public static function editTagsImpl() {
		var e = TreeViewMenus.targetAsTVE;
		var rel = e.treeRelPath;
		var dir = e.treeIsDir;
		if (dir && rel.endsWith("/")) rel = rel.substring(0, rel.length - 1) + ".yy";
		TagEditor.show(rel, dir);
	}
	public static function renameImpl_1(q:TreeViewItemRename) {
		
	}
	static function renameImpl() {
		var d = getItemData(target);

		(cast target:TreeViewItem).showInlineTextbox(function(s) {
			if (s == d.last || s == "" || s == null) return;
			var el:TreeViewElement = cast target;
			var tvDir:TreeViewDir = el.treeParentDir;
			var kind = el.treeIsDir ? "dir" : el.treeKind;
			if (!validate(s, tvDir, d.isDir, d.filter, kind)) return;
			if (d.filter == "file") {
				try {
					var path0 = el.treeRelPath;
					var path1 = Path.join([Path.directory(path0), s]);
					Project.current.renameSync(path0, path1);
					if (d.isDir) Project.current.reload();
				} catch (x:Dynamic) {
					Dialog.showError("Couldn't rename item: " + x);
				}
				return;
			}
			var mode:Int = 2;
			var dlgMode:Int = 0;
			var wantExtras = false;
			if (Project.current.isGMS23) switch (kind) {
				case "notes", "extension": dlgMode = 1;
				default: dlgMode = 2;
			}
			//Main.console.log(kind, dlgMode);
			if (dlgMode > 0) {
				var msg = "Would you like to rename references as well?";
				var exp = "(experimental, make sure to have backups/version control)";
				if (Electron != null) {
					var buttons = [
						"Rename, update references",
						"Rename, update references and code",
						"Just rename",
					];
					if (dlgMode == 1) buttons.splice(1, 1);
					mode = Dialog.showMessageBox({
						message: msg,
						detail: exp,
						buttons: buttons,
						cancelId: 2,
					});
					if (mode == 1 && dlgMode == 1) mode = 2;
				} else {
					mode = Dialog.showConfirm('$msg\n$exp') ? 0 : 2;
				}
			}
			var args:TreeViewItemRename = {
				prefix: d.prefix,
				plural: d.plural,
				single: d.single,
				chain: d.chain,
				last: d.last,
				tvDir: tvDir,
				tvRef: el,
				name: s,
				kind: kind,
				patchRefs: mode < 2,
				patchCode: mode == 1,
			};
			var project = Project.current;
			var oldPath = el.treeFullPath;
			var vi = project.version.config.projectModeId;
			switch (vi) {
				#if !gmedit.no_gmx
				case 1: gmx.GmxManip.rename(args);
				#end
				case 2: {
					if (project.yyUsesGUID) {
						YyManipV22.rename(args);
					} else YyManip.rename(args);
				}
				default: Dialog.showAlert("Can't rename an item for this version!");
			}

			// If you have the tab for the resource open, give it a new file source
			for (tab in document.querySelectorAll(".chrome-tab")) {
				var chromeTab:ChromeTab = cast tab;
				if (chromeTab.gmlFile.path == oldPath) {
					chromeTab.gmlFile.rename(s, el.treeFullPath);
					chromeTab.refresh();
				}
			}
		});
	}
	//
	static function initCreateMenu() {
		var createMenu = new Menu();
		// 2.3 menus:
		var orders = ["before", "inside", "after"];
		for (orderInd in 0 ... 3) {
			var order = orders[orderInd];
			var submenu = new Menu();
			
			// NB! You'll need to add a "resource_<name>_add.png" to /icons/silk
			// when you add new resource types here.
			var resourceTypes = ["sprite", "sound", "script", "note", "shader", "font", "object"];

			if (Preferences.current.assetOrder23 == PrefAssetOrder23.Ascending) {
				resourceTypes.sort((a,b) -> a < b ? -1 : 1);
			} else if (Preferences.current.assetOrder23 == PrefAssetOrder23.Descending) {
				resourceTypes.sort((a,b) -> a > b ? -1 : 1);
			}

			for (dat in resourceTypes) {
				var pair = dat.split("|");
				var kind = pair[0];
				var label = pair[1];
				if (label == null) label = kind.capitalize();
				addLink(submenu, "create-" + kind, label, function() {
					createImpl(kind, orderInd - 1);
				}, "resource_" + kind + "_add");
			}
			//
			var subitem = createMenu.appendOpt({
				id: "sub-" + order,
				label: "Item " + order,
				type: Sub,
				submenu: submenu,
			});
			(cast subitem).yyOnlyV23 = true;
			var arr = (orderInd == 1 ? items.manipDirOnly : items.manipNonRoot);
			arr.push(subitem);
		}
		// non-2.3 menus:
		var onlyV23:Bool = false;
		function addLinkV(menu:Menu, id:String, label:String, fn:Void->Void) {
			var r = addLink(menu, id, label, fn);
			(cast r).yyOnlyV23 = onlyV23;
			return r;
		}
		for (ind in 0 ... 2) {
			var gr = ind > 0;
			var si = gr ? "group" : "item";
			if (ind > 0) createMenu.appendSep("sep-group");
			var s = gr ? "Group" : "Item";
			var kind = gr ? "dir" : "auto";
			onlyV23 = gr ? null : false;
			items.manipNonRoot.push(addLinkV(createMenu, si+"-before", s + " before", function() {
				createImpl(kind, -1);
			}));
			items.manipDirOnly.push(addLinkV(createMenu, si+"-inside", s + " inside", function() {
				createImpl(kind, 0);
			}));
			items.manipNonRoot.push(addLinkV(createMenu, si+"-after", s + " after", function() {
				createImpl(kind, 1);
			}));
		}
		//
		createMenu.appendSep("sep-duplicate");
		items.manipDuplicate = addLink(createMenu, "item-duplicate", "Duplicate", function() {
			var dir = target;
			var d = getItemData(dir);
			Dialog.showPrompt("Name?", d.last, function(s) {
				if (s == "" || s == null) return;
				createImplBoth("auto", 1, dir, s, function(c) {
					var fp = dir.getAttribute(TreeView.attrPath);
					if (Path.extension(fp) == "yy") fp = Path.withExtension(fp, "gml");
					try {
						c.gmlCode = electron.FileWrap.readTextFileSync(fp);
					} catch (x:Dynamic) {
						Main.console.error('Error reading `$fp`:', x);
						c.gmlCode = "";
					}
					return c;
				});
			});
		});
		//
		var createItem = new MenuItem({
			id: "sub-create",
			label: "Create",
			icon: Menu.silkIcon("add"),
			type: Sub,
			submenu: createMenu
		});
		var removeItem = new MenuItem({
			id: "remove",
			label: "Delete",
			icon: Menu.silkIcon("stop_close"),
			click: removeImpl
		});
		var editTagsItem = new MenuItem({
			id: "edit-tags",
			label: "Edit tags",
			icon: Menu.silkIcon("tag_blue"),
			click: editTagsImpl
		});
		var renameItem = new MenuItem({
			id: "rename",
			label: "Rename",
			icon: Menu.silkIcon("textfield_rename"),
			click: renameImpl
		});
		items.manipCreate = createItem;
		items.manipOuter = [createItem, editTagsItem, renameItem, removeItem];
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
	// the following allow for project traversal and are unused in 2.3:
	prefix:String,
	single:String,
	plural:String,
	chain:Array<String>,
	last:String,
	
	/**
	 * Reference element - the thing we clicked on.
	 */
	tvRef:Element,
	
	/**
	 * Tree view directory to insert into.
	 * For order=0, this is the tvRef itself.
	 * For -1/+1, this is the parent of tvRef.
	 */
	tvDir:TreeViewDir,
	
	/** Project reference, defaults to Project.current */
	?pj:Project,
	
	/** [GMS2.2] if set, project JSON should be modified instead of reading-flushing */
	?py:yy.YyProject,
	
	/** [GMS2.2] if set, new resource is inserted before this one */
	?pyBefore:yy.YyProjectResource,
	
	/** [GMS2.2] filled out during call */
	?outGUID:yy.YyGUID,
};
typedef TreeViewItemCreate = {
	>TreeViewItemBase,
	name:String,
	kind:String,
	order:Int, mkdir:Bool,
	/**
	 * A relative path to the newly created item.
	 * For scripts this is a path to GML, for other resources it is a path to YY.
	 */
	?npath:String,
	/** whether to open the freshly made thing (defaults to true) */
	?openFile:Bool,
	/** whether to reveal the freshly made thing in treeview */
	?showInTree:Bool,
	/** initial content for GML files */
	?gmlCode:String,
};
typedef TreeViewItemRename = {
	>TreeViewItemBase,
	name:String,
	kind:String,
	patchRefs:Bool,
	patchCode:Bool,
}
typedef TreeViewItemRemove = {
	>TreeViewItemBase,
	cleanRefs:Bool,
}
typedef TreeViewItemMove = {
	>TreeViewItemBase,
	srcChain:Array<String>,
	srcLast:String,
	srcDir:TreeViewDir,
	srcRef:TreeViewElement,
	order:Int,
}
