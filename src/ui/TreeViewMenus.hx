package ui;
import electron.Menu;
import electron.Dialog;
import haxe.io.Path;
import js.html.Element;
import gml.GmlFile;
using tools.HtmlTools;
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
	public static function openExternal() {
		var path = target.getAttribute(TreeView.attrPath);
		electron.Shell.openItem(path);
	}
	public static function openDirectory() {
		var path = target.getAttribute(TreeView.attrPath);
		electron.Shell.openItem(Path.directory(path));
	}
	//
	public static function showDirMenu(el:Element) {
		target = el;
		openAllItem.enabled = el.querySelector('.item') != null;
		openCombinedItem.enabled = el.querySelector('.item[${TreeView.attrKind}="script"]') != null;
		dirMenu.popupAsync();
	}
	public static function showItemMenu(el:Element) {
		target = el;
		
		itemMenu.popupAsync();
	}
	//
	public static function init() {
		var add_item:MenuItem;
		inline function add(m:Menu, o:MenuItemOptions) {
			add_item = new MenuItem(o);
			m.append(add_item);
			return add_item;
		}
		itemMenu = new Menu();
		add(itemMenu, { label: "Open externally", click: openExternal });
		add(itemMenu, { label: "Show in directory", click: openDirectory });
		//
		dirMenu = new Menu();
		openAllItem = add(dirMenu, { label: "Open all", click: openAll });
		openCombinedItem = add(dirMenu, { label: "Open combined view", click: openCombined });
		//
	}
}
