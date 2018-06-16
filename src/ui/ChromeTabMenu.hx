package ui;
import electron.Menu;
import gml.file.GmlFileBackup;
import gml.file.GmlFileKind;
import js.html.Element;
import js.html.MouseEvent;
import ui.ChromeTabs;
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
	#end
	public static function show(el:ChromeTab, ev:MouseEvent) {
		target = el;
		var file = el.gmlFile;
		var hasFile = file.path != null;
		#if !lwedit
		showInDirectoryItem.enabled = hasFile;
		showInTreeItem.enabled = hasFile;
		showObjectInfo.visible = hasFile && switch (file.kind) {
			case GmlFileKind.GmxObjectEvents, GmlFileKind.YyObjectEvents: true;
			default: false;
		};
		var bk = GmlFileBackup.updateMenu(file);
		if (bk != null) {
			backupsItem.enabled = bk;
			backupsItem.visible = true;
		} else backupsItem.visible = false;
		#end
		menu.popupAsync(ev);
	}
	public static function init() {
		menu = new Menu();
		menu.append(new MenuItem({
			label: "Close",
			accelerator: "CommandOrControl+W",
			click: function() {
			target.querySelector(".chrome-tab-close").click();
		} }));
		menu.append(new MenuItem({
			label: "Close Others",
			accelerator: "CommandOrControl+Shift+W",
			click: function() {
			for (tab in target.parentElement.querySelectorEls(".chrome-tab")) {
				if (tab != target) tab.querySelector(".chrome-tab-close").click();
			}
		} }));
		menu.append(new MenuItem({ label: "Close All", click: function() {
			for (tab in target.parentElement.querySelectorEls(".chrome-tab")) {
				tab.querySelector(".chrome-tab-close").click();
			}
		} }));
		menu.append(new MenuItem({ type: MenuItemType.Sep }));
		#if lwedit
		menu.append(new MenuItem({
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
		menu.append(showInDirectoryItem = new MenuItem({
			label: "Show in directory",
			click: function() {
				electron.FileWrap.showItemInFolder(target.gmlFile.path);
			}
		}));
		if (electron.Electron == null) showInDirectoryItem.visible = false;
		menu.append(showInTreeItem = new MenuItem({
			label: "Show in tree",
			click: function() {
				var tree = TreeView.element;
				var path = target.gmlFile.path;
				var epath = tools.NativeString.escapeProp(path);
				var item = tree.querySelector('.item[${TreeView.attrPath}="$epath"]');
				if (item == null) return;
				var par = item;
				do {
					if (par.classList.contains("dir")) par.classList.add("open");
					par = par.parentElement;
				} while (par != null);
				untyped item.scrollIntoViewIfNeeded();
			}
		}));
		menu.append(showObjectInfo = new MenuItem({
			label: "Object information",
			click: function() {
				var file = target.gmlFile;
				gml.GmlObjectInfo.showFor(file.path, file.name);
			}
		}));
		//
		GmlFileBackup.init();
		menu.append(backupsItem = new MenuItem({
			label: "Previous versions",
			submenu: GmlFileBackup.menu,
			type: Sub,
		}));
		if (electron.Electron == null) backupsItem.visible = false;
		#end
	}
}
