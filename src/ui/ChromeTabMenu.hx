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
 * The little context menu that you see when you right-click a tab.
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
	static var pinItem:MenuItem;
	static var pinAsItem:MenuItem;
	static var pinAsMenu:Menu;
	static var pinAsMenuItems:Array<MenuItem>;
	static var unpinItem:MenuItem;
	static var closeIdleItem:MenuItem;
	public static function show(el:ChromeTab, ev:MouseEvent) {
		target = el;
		var file = el.gmlFile;
		var hasFile = file.path != null;
		
		var tabPrefs = Preferences.current.chromeTabs;
		var pinned = el.classList.contains(ChromeTabs.clPinned);
		var pinLayers = tabPrefs.pinLayers;
		pinItem.visible = !pinned && !pinLayers;
		pinAsItem.visible = pinLayers;
		if (pinLayers) {
			var pinLayer = el.pinLayer;
			for (i => item in pinAsMenuItems) {
				if (item == null) continue;
				item.checked = pinLayer == i;
			}
		}
		unpinItem.visible = pinned;
		closeIdleItem.visible = tabPrefs.idleTime > 0;
		
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
			}
		}));
		menu.append(new MenuItem({
			id: "close-others",
			label: "Close Others",
			accelerator: "CommandOrControl+Shift+W",
			click: function() {
				for (tab in target.parentElement.querySelectorEls(".chrome-tab")) {
					if (tab.classList.contains(ChromeTabs.clPinned)) continue;
					if (tab != target) tab.querySelector(".chrome-tab-close").click();
				}
			}
		}));
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
			id: "close-all-to-right",
			label: "Close All to Right",
			click: function() {
				var tabs = target.parentElement.querySelectorEls(".chrome-tab");
				var index = tabs.length;
				for(i in 0...index) {
					var tab = tabs[i];
					if (tab == target) {
						index = i;
						continue;
					}
					if (i > index) {
						tab.querySelector(".chrome-tab-close").click();
					}
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
			icon: Menu.silkIcon("show_in_directory"),
			click: function() {
				electron.FileWrap.showItemInFolder(target.gmlFile.path);
			}
		}));
		if (electron.Electron == null) showInDirectoryItem.visible = false;
		
		menu.append(showInTreeItem = new MenuItem({
			id: "show-in-tree",
			label: "Show in tree",
			icon: Menu.silkIcon("application_side_tree_show"),
			click: function() {
				var item = TreeView.find(true, { path: target.gmlFile.path });
				if (item != null) TreeView.showElement(item, true);
			}
		}));
		
		menu.append(findReferences = new MenuItem({
			id: "find-references",
			label: "Find references",
			icon: Menu.silkIcon("find_references"),
			click: function() GlobalSearch.findReferences(target.gmlFile.name)
		}));
		
		menu.append(showObjectInfo = new MenuItem({
			id: "object-information",
			label: "Object information",
			icon: Menu.silkIcon("information"),
			click: function() {
				var file = target.gmlFile;
				gml.GmlObjectInfo.showFor(file.path, file.name);
			}
		}));
		
		menu.appendSep("pin-sep");
		pinAsMenu = new Menu();
		pinAsMenuItems = [for (_ in 0 ... 10) null];
		for (_i in -9 ... 1) {
			var i = -_i;
			pinAsMenuItems[i] = pinAsMenu.appendOpt({
				id: "pinAs" + i,
				label: i == 0 ? "Unpinned" : "Layer " + i,
				type: MenuItemType.Check,
				click: function() {
					ChromeTabs.impl.setTabPinLayer(target, i, true);
					ChromeTabs.impl.layoutTabs();
				},
			});
		}
		pinAsItem = menu.appendOpt({
			id: "pinAs",
			label: "Pin...",
			icon: Menu.silkIcon("pin"),
			submenu: pinAsMenu,
		});
		pinItem = menu.appendOpt({
			id: "pin",
			label: "Pin",
			icon: Menu.silkIcon("pin"),
			click: function() {
				ChromeTabs.impl.setTabPinLayer(target, 1);
				ChromeTabs.impl.layoutTabs();
			}
		});
		unpinItem = menu.appendOpt({
			id: "unpin",
			label: "Unpin",
			icon: Menu.silkIcon("pin"),
			click: function() {
				ChromeTabs.impl.setTabPinLayer(target, 0);
				ChromeTabs.impl.layoutTabs();
			}
		});
		
		closeIdleItem = menu.appendOpt({
			id: "close-idle",
			label: "Close idle tabs",
			click: function() {
				for (tab in target.parentElement.querySelectorEls(".chrome-tab." + ChromeTabs.clIdle)) {
					tab.querySelector(".chrome-tab-close").click();
				}
			}
		});
		
		//
		menu.appendSep("backups-sep");
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
