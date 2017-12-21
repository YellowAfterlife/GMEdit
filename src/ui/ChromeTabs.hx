package ui;
import electron.Dialog;
import electron.Electron;
import js.html.BeforeUnloadEvent;
import js.html.CustomEvent;
import js.html.Element;
import js.html.Event;
import tools.HtmlTools;
import Main.window;
import Main.document;

/**
 * ...
 * @author YellowAfterlife
 */
class ChromeTabs {
	public static var element:Element;
	public static var impl:ChromeTabsImpl;
	public static function init() {
		element = Main.document.querySelector("#tabs");
		impl = new ChromeTabsImpl();
		impl.init(element, {
			tabOverlapDistance: 14, minWidth: 45, maxWidth: 160
		});
		element.addEventListener("activeTabChange", function(e:CustomEvent) {
			var tabEl:ChromeTab = e.detail.tabEl;
			var gmlFile = tabEl.gmlFile;
			if (gmlFile == null) {
				gmlFile = gml.GmlFile.next;
				if (gmlFile == null) return;
				gml.GmlFile.next = null;
				gmlFile.tabEl = cast tabEl;
				tabEl.gmlFile = gmlFile;
				tabEl.title = gmlFile.path;
			}
			gml.GmlFile.current = gmlFile;
			Main.aceEditor.setSession(gmlFile.session);
		});
		element.addEventListener("tabClose", function(e:CustomEvent) {
			var tabEl:ChromeTab = e.detail.tabEl;
			var gmlFile = tabEl.gmlFile;
			if (gmlFile == null) return;
			if (gmlFile.changed) {
				var bt = Dialog.showMessageBox({
					buttons: ["Yes", "No", "Cancel"],
					message: "Do you want to save the current changes?",
					title: "Unsaved changes in " + gmlFile.name,
					cancelId: 2,
				});
				switch (bt) {
					case 0: gmlFile.save();
					case 1: { };
					default: e.preventDefault();
				}
			}
		});
		element.addEventListener("tabRemove", function(e:CustomEvent) {
			if (impl.tabEls.length == 0) {
				Main.aceEditor.session = WelcomePage.session;
			}
		});
		// https://github.com/electron/electron/issues/7977:
		window.addEventListener("beforeunload", function(e:BeforeUnloadEvent) {
			var changedTabs = document.querySelectorAll('.chrome-tab.chrome-tab-changed');
			if (changedTabs.length == 0) return;
			//
			e.returnValue = cast false;
			window.setTimeout(function() {
				for (tabNode in changedTabs) {
					var tabEl:Element = cast tabNode;
					tabEl.querySelector(".chrome-tab-close").click();
				}
				if (document.querySelectorAll('.chrome-tab.chrome-tab-changed').length == 0) {
					Electron.remote.getCurrentWindow().close();
				}
			});
		});
		//
		return impl;
	}
}
@:native("ChromeTabs") extern class ChromeTabsImpl {
	public function new():Void;
	public function init(el:Element, opt:Dynamic):Void;
	public function addTab(tab:Dynamic):Dynamic;
	public var tabEls(default, never):Array<Element>;
}
