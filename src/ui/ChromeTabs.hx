package ui;
import electron.Dialog;
import electron.Electron;
import file.kind.gml.KGmlScript;
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
import plugins.PluginAPI;
import plugins.PluginEvents;
import ui.liveweb.LiveWeb;
import ui.liveweb.LiveWebState;
using tools.NativeString;
using tools.HtmlTools;

/**
 * A wrapper and helpers for Chrome Tabs library.
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
	@:keep public static inline function getTabs():ChromeTabList {
		return cast element.querySelectorAll(".chrome-tab");
	}
	public static function sync(gmlFile:GmlFile, ?isNew:Bool) {
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
		if (isNew) {
			if (gmlFile.path != null
				&& gmlFile.codeEditor != null
				&& Std.is(gmlFile.codeEditor.kind, file.kind.KGml)
				&& (cast gmlFile.codeEditor.kind:file.kind.KGml).canSyntaxCheck
			) {
				var check = inline parsers.linter.GmlLinter.getOption((q)->q.onLoad);
				if (check) window.setTimeout(function() {
					if (GmlFile.current == gmlFile) {
						parsers.linter.GmlLinter.runFor(gmlFile.codeEditor);
					}
				}, 0);
			}
			ui.ext.Bookmarks.onFileOpen(gmlFile);
			PluginEvents.fileOpen({file:gmlFile});
		}
		PluginEvents.activeFileChange({file:gmlFile});
	}
	public static function init() {
		element = Main.document.querySelector("#tabs");
		if (electron.Electron == null || Main.moduleArgs.exists("electron-window-frame")) {
			element.classList.remove("has-system-buttons");
			for (btn in document.querySelectorAll(".system-button:not(.preferences)")) {
				btn.parentElement.removeChild(btn);
			}
		}
		impl = new ChromeTabsImpl();
		var opt:Dynamic = { tabOverlapDistance: 14 };
		js.lib.Object.assign(opt, Preferences.current.chromeTabs);
		impl.init(element, opt);
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
			var makeFile = (gmlFile == null);
			if (makeFile) { // bind newly made gmlFile
				gmlFile = GmlFile.next;
				if (gmlFile == null) return;
				GmlFile.next = null;
				gmlFile.tabEl = cast tabEl;
				tabEl.gmlFile = gmlFile;
				//tabEl.title = gmlFile.path != null ? gmlFile.path : gmlFile.name;
				tabEl.context = gmlFile.context;
				tabEl.addEventListener("contextmenu", function(e:MouseEvent) {
					e.preventDefault();
					ChromeTabMenu.show(tabEl, e);
				});
				tabEl.addEventListener("mouseenter", function(e:MouseEvent) {
					hintEl.setInnerText(gmlFile.name);
					hintEl.style.display = "block";
					var pos = impl.tabPositions[impl.tabEls.indexOf(tabEl)];
					hintEl.style.left = (pos.left
						+ tabEl.offsetWidth / 2
						+ tabEl.parentElement.offsetLeft
						- hintEl.offsetWidth / 2
					) + "px";
					hintEl.style.top = (36 + pos.top) + "px";
				});
				tabEl.addEventListener("mouseleave", hideHint);
				tabEl.addEventListener("mousedown", hideHint);
				#if lwedit
				GmlSeekData.add(gmlFile.path, KGmlScript.inst);
				#end
			}
			sync(gmlFile, makeFile);
			if (Std.is(gmlFile.editor, editors.EditCode)) {
				window.setTimeout(function() {
					Main.aceEditor.focus();
				});
			}
		});
		element.addEventListener("tabClose", function(e:CustomEvent) {
			var tabEl:ChromeTab = e.detail.tabEl;
			if (tabEl.classList.contains("chrome-tab-force-close")) return;
			var gmlFile = tabEl.gmlFile;
			if (gmlFile == null) return;
			#if (lwedit)
			if (Std.is(gmlFile.kind, file.kind.gml.KGmlScript)) {
				if (gmlFile.getAceSession().getValue().length > 0) {
					if (!Dialog.showConfirmWarn(
						"Are you sure you want to discard this tab? Contents will be lost"
					)) e.preventDefault();
				}
			} else
			#end
			if (gmlFile.changed) {
				if (gmlFile.path != null) {
					var bt:Int;
					if (Electron == null) {
						bt = Dialog.showConfirmWarn(
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
			if (closedFile != null) {
				closedFile.close();
				ui.ext.Bookmarks.onFileClose(closedFile);
				PluginEvents.fileClose({ file: closedFile, tab: closedTab });
			}
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
			#if lwedit
			LiveWebState.save();
			#else
			if (Project.current.path != "") { // not just sitting on "recent projects"
				e.preventDefault();
				e.returnValue = cast "";
			}
			#end
		});
		//
		if (document.hasFocus()) {
			document.documentElement.setAttribute("hasFocus", "");
			electron.WindowsAccentColors.updateFocus(true);
		} else {
			electron.WindowsAccentColors.updateFocus(false);
		}
		window.addEventListener("focus", function(_) {
			document.documentElement.setAttribute("hasFocus", "");
			electron.WindowsAccentColors.updateFocus(true);
			if (GmlFile.current != null) GmlFile.current.checkChanges();
		});
		window.addEventListener("blur", function(_) {
			document.documentElement.removeAttribute("hasFocus");
			electron.WindowsAccentColors.updateFocus(false);
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
	public function layoutTabs():Void;
	public var tabEls(default, never):Array<ChromeTab>;
	public var tabPositions(default, never):Array<{left:Int, top:Int}>;
	public var options:Dynamic;
}
extern class ChromeTab extends Element {
	public var gmlFile:GmlFile;
	//
	public var closeButton(get, never):Element;
	private inline function get_closeButton():Element {
		return this.querySelector(".chrome-tab-close");
	}
	//
	public var tabTitleText(get, never):Element;
	private inline function get_tabTitleText():Element {
		return this.querySelector(".chrome-tab-title-text");
	}
	//
	public var tabText(get, set):String;
	private inline function get_tabText():String {
		return tabTitleText.innerText;
	}
	private inline function set_tabText(s:String):String {
		tabTitleText.innerText = s;
		return s;
	}
	//
	public var context(get, set):String;
	private inline function get_context():String {
		return getAttribute(ChromeTabs.attrContext);
	}
	private inline function set_context(s:String):String {
		setAttribute(ChromeTabs.attrContext, s);
		return s;
	}
	//
	public var isOpen(get, never):Bool;
	private inline function get_isOpen():Bool {
		return classList.contains("chrome-tab-current");
	}

	public inline function refresh():Void {
		tabText = gmlFile.name;
		context = gmlFile.context;
	}
}
extern class ChromeTabList implements ArrayAccess<ChromeTab> {
	public var length(default, never):Int;
	public function item(index:Int):ChromeTab;
}
