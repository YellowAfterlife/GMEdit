package ui;
import electron.Menu;
import electron.Dialog;
import gml.Project;
import haxe.io.Path;
import js.html.Element;
import gml.file.*;
using tools.HtmlTools;
using tools.NativeString;
using tools.NativeArray;
import Main.*;

/**
 * Context menus for treeview items
 * @author YellowAfterlife
 */
class TreeViewMenus {
	/** treeview element that a menu was invoked at */
	public static var target:Element;
	public static var itemMenu:Menu;
	public static var dirMenu:Menu;
	//
	public static var openAllItem:MenuItem;
	public static function openAll() {
		var found = 0;
		var els = target.querySelectorEls('.item');
		if (els.length < 50 || Dialog.showMessageBox({
			message: "Are you sure that you want to open " + els.length + " tabs?",
			buttons: ["Yes", "No"],
			cancelId: 1,
		}) == 0) for (el in els) {
			window.setTimeout(function() {
				GmlFile.open(el.innerText, el.getAttribute(TreeView.attrPath));
			}, found * 50);
			found += 1;
		}
	}
	//
	public static var openCombinedItem:MenuItem;
	public static function openCombined() {
		var items = [];
		var error = "";
		var mpath = "";
		for (item in target.querySelectorEls('.item[${TreeView.attrKind}="script"]')) {
			var path = item.getAttribute(TreeView.attrPath);
			var ident = item.getAttribute(TreeView.attrIdent);
			if (mpath != "") mpath += "|";
			mpath += path;
			items.push({ name: ident, path: path });
		}
		if (items.length > 0) {
			var name = target.querySelector('.header').innerText;
			GmlFile.openTab(new GmlFile(name, mpath, Multifile, items));
		}
	}
	//
	static var shaderItems:Array<MenuItem>;
	static function openYyShader(ext:String) {
		var name = target.getAttribute(TreeView.attrIdent) + "." + ext;
		var path = target.getAttribute(TreeView.attrPath);
		path = Path.withoutExtension(path) + "." + ext;
		GmlFile.open(name, path);
	}
	//
	static var removeFromRecentProjectsItem:MenuItem;
	static function removeFromRecentProjects() {
		RecentProjects.remove(target.getAttribute(TreeView.attrPath));
		target.parentElement.removeChild(target);
	}
	//
	static var changeIconItem:MenuItem;
	public static function changeIcon() {
		var pj = Project.current;
		var itemPath = target.getAttribute(TreeView.attrPath);
		var def = pj.path != "" ? pj.dir : Path.directory(itemPath);
		var files = Dialog.showOpenDialog({
			title: "Hello",
			defaultPath: def,
			filters: [
				new DialogFilter("Images", ["png"]),
				new DialogFilter("All files", ["*"]),
			],
		});
		if (files == null || files[0] == null) return;
		var path = files[0];
		if (pj.path != "") {
			ProjectStyle.setItemThumb({
				thumb: path,
				ident: target.getAttribute(TreeView.attrIdent),
				kind: target.getAttribute(TreeView.attrKind),
				rel: target.getAttribute(TreeView.attrRel),
			});
		} else {
			var th = itemPath + ".png";
			electron.FileSystem.copyFileSync(path, th);
			TreeView.setThumb(itemPath, th + "?v=" + Date.now().getTime());
		}
	}
	//
	static function openHere() {
		var path = target.getAttribute(TreeView.attrPath);
		var pair = GmlFileKindTools.detect(path);
		if (pair.kind == GmlFileKind.Extern) {
			pair.kind = GmlFileKind.Plain;
		}
		var file = new GmlFile(target.title, path, pair.kind, pair.data);
		GmlFile.openTab(file);
	}
	public static function openExternal() {
		var path = target.getAttribute(TreeView.attrPath);
		electron.Shell.openItem(path);
	}
	public static function openDirectory() {
		var path = target.getAttribute(TreeView.attrPath);
		electron.Shell.showItemInFolder(path);
	}
	//
	public static function showDirMenu(el:Element) {
		target = el;
		openAllItem.enabled = el.querySelector('.item') != null;
		openCombinedItem.enabled = el.querySelector('.item[${TreeView.attrKind}="script"]') != null;
		dirMenu.popupAsync();
	}
	public static function showItemMenu(el:Element) {
		var z:Bool;
		target = el;
		var kind = el.getAttribute(TreeView.attrKind);
		z = gml.GmlAPI.version == v2 && kind == "shader";
		shaderItems.forEach(function(q) q.visible = z);
		removeFromRecentProjectsItem.visible = kind == "project";
		//changeIconItem.visible = kind != "project";
		itemMenu.popupAsync();
	}
	//
	public static function init() {
		function add(m:Menu, o:MenuItemOptions) {
			var r = new MenuItem(o);
			m.append(r);
			return r;
		}
		inline function addLink(m:Menu, label:String, click:Void->Void) {
			return add(m, { label: label, click: click });
		}
		//
		changeIconItem = new MenuItem({ label: "Change icon", click: changeIcon });
		//
		itemMenu = new Menu();
		shaderItems = [
			addLink(itemMenu, "Open vertex shader", function() openYyShader("vsh")),
			addLink(itemMenu, "Open fragment shader", function() openYyShader("fsh")),
		];
		addLink(itemMenu, "Open here", openHere);
		addLink(itemMenu, "Open externally", openExternal);
		addLink(itemMenu, "Show in directory", openDirectory);
		removeFromRecentProjectsItem =
			addLink(itemMenu, "Remove from Recent projects", removeFromRecentProjects);
		itemMenu.append(changeIconItem);
		//
		dirMenu = new Menu();
		openAllItem = addLink(dirMenu, "Open all", openAll);
		openCombinedItem = addLink(dirMenu, "Open combined view", openCombined);
		dirMenu.append(changeIconItem);
		//
	}
}
