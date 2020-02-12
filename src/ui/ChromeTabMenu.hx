package ui;
import electron.Menu;
import gml.file.GmlFileBackup;
import js.html.Element;
import js.html.MouseEvent;
import ui.ChromeTabs;
import ui.treeview.TreeView;
import file.kind.gmx.*;
import file.kind.yy.*;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class ChromeTabMenu {
	public static var target:ChromeTab;
	public static var menu:Menu;
	#if !lwedit
	static var showInDirectoryItem:MenuItem;
	static var showInTreeItem:MenuItem;
	static var backupsItem:MenuItem;
	static var showObjectInfo:MenuItem;
	static var openExternally:MenuItem;
	static var findReferences:MenuItem;
	#end
	public static function show(el:ChromeTab, ev:MouseEvent) {
		target = el;
		var file = el.gmlFile;
		var hasFile = file.path != null;
		#if !lwedit
		showInDirectoryItem.enabled = hasFile;
		openExternally.enabled = hasFile;
		showInTreeItem.enabled = ~/^\w+$/g.match(file.name) && gml.GmlAPI.gmlKind.exists(file.name);
		showObjectInfo.visible = hasFile && (Std.is(file.kind, KGmxEvents) || Std.is(file.kind, KYyEvents));
		var bk = GmlFileBackup.updateMenu(file);
		if (bk != null) {
			backupsItem.enabled = bk;
			backupsItem.visible = true;
		} else backupsItem.visible = false;
		#end
		plugins.PluginEvents.tabMenu({target:el,event:ev});
		menu.popupAsync(ev);
	}
	public static function init() {
		menu = new Menu();
		menu.append(new MenuItem({
			id: "close",
			label: "Close",
			accelerator: "CommandOrControl+W",
			click: function() {
			target.querySelector(".chrome-tab-close").click();
		} }));
		menu.append(new MenuItem({
			id: "close-others",
			label: "Close Others",
			accelerator: "CommandOrControl+Shift+W",
			click: function() {
			for (tab in target.parentElement.querySelectorEls(".chrome-tab")) {
				if (tab != target) tab.querySelector(".chrome-tab-close").click();
			}
		} }));
		menu.append(new MenuItem({
			id: "close-all",
			label: "Close All",
			click: function() {
				for (tab in target.parentElement.querySelectorEls(".chrome-tab")) {
					tab.querySelector(".chrome-tab-close").click();
				}
			}
		}));
		menu.append(new MenuItem({
			id: "close-sep",
			type: MenuItemType.Sep
		}));
		#if lwedit
		menu.append(new MenuItem({
			id: "rename",
			label: "Rename",
			click: function() {
				var gmlFile = target.gmlFile;
				var s0 = gmlFile.name;
				electron.Dialog.showPrompt("New tab name?", s0, function(s1) {
					if (s1 == null || s1 == "" || s1 == s0) return;
					for (tab in ChromeTabs.impl.tabEls) if (tab.gmlFile.name == s1) {
						Main.window.alert("A tab with this name already exists.");
						return;
					}
					parsers.GmlSeekData.rename(s0, s1);
					gmlFile.name = s1;
					gmlFile.path = s1;
					target.querySelector(".chrome-tab-title-text").setInnerText(s1);
					ChromeTabs.sync(gmlFile);
				});
			}
		}));
		#else
		menu.append(openExternally = new MenuItem({
			id: "open-externally",
			label: "Open externally",
			click: function() {
				electron.FileWrap.openExternal(target.gmlFile.path);
			}
		}));
		if (electron.Electron == null) openExternally.visible = false;
		menu.append(showInDirectoryItem = new MenuItem({
			id: "show-in-directory",
			label: "Show in directory",
			click: function() {
				electron.FileWrap.showItemInFolder(target.gmlFile.path);
			}
		}));
		if (electron.Electron == null) showInDirectoryItem.visible = false;
		menu.append(showInTreeItem = new MenuItem({
			id: "show-in-tree",
			label: "Show in tree",
			click: function() {
				var tree = TreeView.element;
				var path = target.gmlFile.path;
				var epath = tools.NativeString.escapeProp(path);
				var item = tree.querySelector('.item[${TreeView.attrPath}="$epath"]');
				if (item == null) return;
				//
				var flashStep = 0;
				var flashInt = 0;
				function flashFunc() {
					if (flashStep % 2 == 0) {
						item.classList.add("show-in-treeview-flash");
					} else item.classList.remove("show-in-treeview-flash");
					if (++flashStep >= 6) Main.window.clearInterval(flashInt);
				}
				flashInt = Main.window.setInterval(flashFunc, 300);
				//
				var par = item, check = false;
				do {
					if (par.classList.contains(TreeView.clDir) && !par.classList.contains(TreeView.clOpen)) {
						par.classList.add(TreeView.clOpen);
						check = true;
					}
					par = par.parentElement;
				} while (par != null && !par.classList.contains("treeview"));
				if (check && par != null) TreeView.ensureThumbs(par);
				untyped item.scrollIntoViewIfNeeded();
			}
		}));
		menu.append(findReferences = new MenuItem({
			id: "find-references",
			label: "Find references",
			click: function() GlobalSearch.findReferences(target.gmlFile.name)
		}));
		menu.append(showObjectInfo = new MenuItem({
			id: "object-information",
			label: "Object information",
			click: function() {
				var file = target.gmlFile;
				gml.GmlObjectInfo.showFor(file.path, file.name);
			}
		}));
		//
		GmlFileBackup.init();
		menu.append(backupsItem = new MenuItem({
			id: "backups",
			label: "Previous versions",
			submenu: GmlFileBackup.menu,
			type: Sub,
		}));
		if (electron.Electron == null) backupsItem.visible = false;
		#end
	}
}
