package ui;
import electron.Dialog;
import electron.Electron;
import gml.file.GmlFile;
import gml.Project;
import js.html.BeforeUnloadEvent;
import js.html.CustomEvent;
import js.html.Element;
import js.html.Event;
import Main.window;
import Main.document;
import js.html.MouseEvent;
import parsers.GmlSeekData;
import parsers.GmlSeeker;
import ui.liveweb.LiveWeb;
using tools.NativeString;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class ChromeTabs {
	public static var element:Element;
	public static var impl:ChromeTabsImpl;
	public static var pathHistory:Array<String> = [];
	public static var attrContext:String = "data-context";
	public static inline var pathHistorySize:Int = 32;
	public static inline function addTab(title:String) {
		impl.addTab({ title: title });
	}
	public static function sync(gmlFile:GmlFile) {
		var prev = GmlFile.current;
		if (prev != WelcomePage.file) {
			pathHistory.unshift(prev.context);
			if (pathHistory.length > pathHistorySize) pathHistory.pop();
		}
		GmlFile.current = gmlFile;
		// set container attributes so that themes can style the editor per them:
		var ctr = Main.aceEditor.container;
		if (gmlFile != WelcomePage.file) {
			ctr.setAttribute("file-name", gmlFile.name);
			ctr.setAttribute("file-path", gmlFile.path);
			ctr.setAttribute("file-kind", gmlFile.kind.getName());
		} else {
			ctr.removeAttribute("file-name");
			ctr.removeAttribute("file-path");
			ctr.removeAttribute("file-kind");
		}
		//
		prev.editor.focusLost(gmlFile.editor);
		gmlFile.focus();
		gmlFile.editor.focusGain(prev.editor);
	}
	public static function init() {
		element = Main.document.querySelector("#tabs");
		if (electron.Electron == null) {
			element.classList.remove("has-system-buttons");
			for (btn in document.querySelectorAll(".system-button:not(.preferences)")) {
				btn.parentElement.removeChild(btn);
			}
		}
		impl = new ChromeTabsImpl();
		impl.init(element, {
			tabOverlapDistance: 14, minWidth: 45, maxWidth: 160
		});
		//
		ChromeTabMenu.init();
		//
		var hintEl = document.createDivElement();
		hintEl.classList.add("chrome-tabs-hint");
		hintEl.setInnerText("Bock?");
		element.parentElement.appendChild(hintEl);
		function hideHint(?ev:Event):Void {
			hintEl.style.display = "none";
		}
		//
		element.addEventListener("activeTabChange", function(e:CustomEvent) {
			var tabEl:ChromeTab = e.detail.tabEl;
			var gmlFile = tabEl.gmlFile;
			if (gmlFile == null) { // bind newly made gmlFile
				gmlFile = GmlFile.next;
				if (gmlFile == null) return;
				GmlFile.next = null;
				gmlFile.tabEl = cast tabEl;
				tabEl.gmlFile = gmlFile;
				//tabEl.title = gmlFile.path != null ? gmlFile.path : gmlFile.name;
				tabEl.setAttribute(attrContext, gmlFile.context);
				tabEl.addEventListener("contextmenu", function(e:MouseEvent) {
					e.preventDefault();
					ChromeTabMenu.show(tabEl, e);
				});
				tabEl.addEventListener("mouseenter", function(e:MouseEvent) {
					hintEl.setInnerText(gmlFile.name);
					hintEl.style.display = "block";
					var x = impl.tabPositions[impl.tabEls.indexOf(tabEl)]
						+ tabEl.offsetWidth / 2
						+ tabEl.parentElement.offsetLeft
						- hintEl.offsetWidth / 2;
					hintEl.style.left = x + "px";
				});
				tabEl.addEventListener("mouseleave", hideHint);
				tabEl.addEventListener("mousedown", hideHint);
				#if lwedit
				GmlSeekData.add(gmlFile.path);
				#end
			}
			sync(gmlFile);
		});
		element.addEventListener("tabClose", function(e:CustomEvent) {
			var tabEl:ChromeTab = e.detail.tabEl;
			if (tabEl.classList.contains("chrome-tab-force-close")) return;
			var gmlFile = tabEl.gmlFile;
			if (gmlFile == null) return;
			#if (lwedit)
			if (gmlFile.kind == Normal) {
				if (gmlFile.getAceSession().getValue().length > 0) {
					if (!window.confirm(
						"Are you sure you want to discard this tab? Contents will be lost"
					)) e.preventDefault();
				}
			} else
			#end
			if (gmlFile.changed) {
				if (gmlFile.path != null) {
					var bt:Int;
					if (Electron == null) {
						bt = window.confirm(
							"Are you sure you want to close " + gmlFile.name + "?" +
							"\nThere are unsaved changes."
						) ? 1 : 2;
					} else bt = Dialog.showMessageBox({
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
				else {
					var bt = Dialog.showMessageBox({
						buttons: ["Yes", "No"],
						message: "Changes cannot be saved (not a file). Stay here?",
						title: "Unsaved changes in " + gmlFile.name,
						cancelId: 0,
					});
					switch (bt) {
						case 1: { };
						default: e.preventDefault();
					}
				}
			} // changed
		});
		element.addEventListener("tabRemove", function(e:CustomEvent) {
			//
			var closedTab:ChromeTab = e.detail.tabEl;
			var closedFile = closedTab.gmlFile;
			if (closedFile != null) closedFile.close();
			//
			if (impl.tabEls.length == 0) {
				sync(WelcomePage.file);
			} else if (closedTab.classList.contains("chrome-tab-current")) {
				var tab:Element = null;
				while (tab == null && pathHistory.length > 0) {
					tab = document.querySelector('.chrome-tab[' + attrContext + '="'
						+ pathHistory.shift().escapeProp() + '"]'
					);
				}
				if (tab == null) tab = e.detail.prevTab;
				if (tab == null) tab = e.detail.nextTab;
				if (tab == null) {
					sync(WelcomePage.file);
				} else impl.setCurrentTab(tab);
			}
		});
		#if lwedit
		element.addEventListener("dblclick", function(e:MouseEvent) {
			if (e.target != element.querySelector(".chrome-tabs-content")) return;
			LiveWeb.newTabDialog();
		});
		#end
		//
		if (Electron!=null) window.addEventListener("beforeunload", function(e:BeforeUnloadEvent) {
			var changedTabs = document.querySelectorAll('.chrome-tab.chrome-tab-changed');
			if (changedTabs.length == 0) {
				for (tabNode in element.querySelectorAll('.chrome-tab')) {
					var tabEl:ChromeTab = cast tabNode;
					var file = tabEl.gmlFile;
					if (file != null) file.close();
				}
				if (Project.current != null) Project.current.close();
				return;
			}
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
		else window.addEventListener("beforeunload", function(e:BeforeUnloadEvent) {
			LiveWeb.saveState();
		});
		//
		window.addEventListener("focus", function(_) {
			if (GmlFile.current != null) GmlFile.current.checkChanges();
		});
		//
		return impl;
	}
}
@:native("ChromeTabs") extern class ChromeTabsImpl {
	public function new():Void;
	public function init(el:Element, opt:Dynamic):Void;
	public function addTab(tab:Dynamic):Dynamic;
	public function setCurrentTab(tab:Element):Void;
	public function removeTab(tabEl:ChromeTab):Void;
	public var tabEls(default, never):Array<ChromeTab>;
	public var tabPositions(default, never):Array<Float>;
}
extern class ChromeTab extends Element {
	public var gmlFile:GmlFile;
}
