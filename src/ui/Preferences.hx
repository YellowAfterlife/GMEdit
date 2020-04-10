package ui;
import ace.AceWrap;
import electron.FileSystem;
import electron.FileWrap;
import electron.Menu;
import file.kind.misc.KSnippets;
import gml.GmlAPI;
import gml.file.GmlFile;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.io.Path;
import js.html.Element;
import js.html.FieldSetElement;
import js.html.InputElement;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.SelectElement;
import js.html.Window;
import Main.document;
import Main.console;
import tools.Dictionary;
import tools.NativeObject;
import ui.treeview.TreeView;
import ui.preferences.PrefData;
import ui.preferences.*;
using tools.HtmlTools;

/**
 * User preferences are managed here!
 * @author YellowAfterlife
 */
class Preferences {
	public static var path:String = "user-preferences";
	public static var current:PrefData;
	public static var element:Element;
	public static var subMenu:Element;
	public static var menuMain:Element;
	/**
	 * Changes the active sub-menu
	 */
	public static function setMenu(el:Element) {
		if (subMenu != el) {
			if (subMenu != null) element.removeChild(subMenu);
			subMenu = el;
			element.appendChild(el);
		}
		return el;
	}
	public static function buildMain():Element {
		var mm = Main.document.createDivElement();
		ui.preferences.PrefMenu.build(mm);
		Preferences.menuMain = mm;
		plugins.PluginEvents.preferencesBuilt({target:mm});
		return mm;
	}
	//
	public static function addGroup(out:Element, legend:String):FieldSetElement {
		var fs = document.createFieldSetElement();
		fs.classList.add("group");
		var lg = document.createLegendElement();
		lg.innerText = legend;
		fs.appendChild(lg);
		out.appendChild(fs);
		return fs;
	}
	public static function addRadios(out:Element, legend:String, curr:String, names:Array<String>, fn:String->Void) {
		var fs = document.createFieldSetElement();
		fs.classList.add("radios");
		var lg = document.createLegendElement();
		lg.innerText = legend;
		fs.appendChild(lg);
		for (name in names) {
			var id = createValidIdFromString(name);
			var rad = document.createInputElement();
			rad.type = "radio";
			rad.name = legend;
			rad.value = name;
			rad.id = id;
			rad.addEventListener("change", function(_) {
				fn(name);
			});
			if (curr == name) rad.checked = true;
			var lb = document.createLabelElement();
			lb.htmlFor = id;
			lb.appendChild(rad);
			lb.appendChild(document.createTextNode(name));
			fs.appendChild(lb);
			fs.appendChild(document.createBRElement());
		}
		out.appendChild(fs);
		return fs;
	}
	public static function addDropdown(out:Element, legend:String, curr:String, names:Array<String>, fn:String->Void) {
		var ctr = document.createDivElement();
		ctr.classList.add("select");
		//
		var lb = document.createLabelElement();
		lb.htmlFor = legend;
		lb.appendChild(document.createTextNode(legend));
		ctr.appendChild(lb);
		//
		var sel = document.createSelectElement();
		for (name in names) {
			var opt = document.createOptionElement();
			opt.value = name;
			opt.appendChild(document.createTextNode(name));
			sel.appendChild(opt);
		}
		sel.addEventListener("change", function(_) {
			fn(sel.value);
		});
		sel.value = curr;
		ctr.appendChild(sel);
		//
		out.appendChild(ctr);
		return ctr;
	}
	public static function addCheckbox(out:Element, legend:String, curr:Bool, fn:Bool->Void):Element {
		var id = createValidIdFromString(legend);
		var ctr = document.createDivElement();
		ctr.classList.add("checkbox");
		var cb = document.createInputElement();
		cb.type = "checkbox";
		cb.checked = curr;
		cb.name = legend;
		cb.addEventListener("change", function(_) {
			fn(cb.checked);
		});
		cb.id = id;
		// ctr.appendChild(cb);
		var lb = document.createLabelElement();
		lb.htmlFor = id;
		lb.appendChild(cb);
		lb.appendChild(document.createTextNode(legend));
		ctr.appendChild(lb);
		out.appendChild(ctr);
		return ctr;
	}
	public static function addInput(out:Element, legend:String, curr:String, fn:String->Void):Element {
		var ctr = document.createDivElement();
		ctr.classList.add("input");
		//
		var lb = document.createLabelElement();
		lb.htmlFor = legend;
		lb.appendChild(document.createTextNode(legend));
		ctr.appendChild(lb);
		//
		var cb = document.createInputElement();
		cb.type = "text";
		cb.value = curr;
		cb.name = legend;
		cb.addEventListener("change", function(_) {
			fn(cb.value);
		});
		cb.addEventListener("keydown", function(e:KeyboardEvent) {
			if (e.keyCode == KeyboardEvent.DOM_VK_RETURN) fn(cb.value);
		});
		ctr.appendChild(cb);
		//
		out.appendChild(ctr);
		return ctr;
	}
	public static function addIntInput(out:Element, legend:String, val:Int, fn:Int->Void):Element {
		var fd:InputElement = null;
		var el = addInput(out, legend, val != null ? ("" + val) : "", function(s:String) {
			var v = Std.parseInt(s);
			if (v != null) {
				fd.classList.remove("error");
				fn(v);
			} else fd.classList.add("error");
		});
		fd = el.querySelectorAuto("input");
		return el;
	}
	public static function addFloatInput(out:Element, legend:String, val:Float, fn:Float->Void):Element {
		var fd:InputElement = null;
		var el = addInput(out, legend, val != null ? ("" + val) : "", function(s:String) {
			var v = Std.parseFloat(s);
			if (!Math.isNaN(v)) {
				fd.classList.remove("error");
				fn(v);
			} else fd.classList.add("error");
		});
		fd = el.querySelectorAuto("input");
		return el;
	}
	public static function addButton(out:Element, text:String, fn:Void->Void):Element {
		var ctr = document.createDivElement();
		ctr.classList.add("button");
		var el = document.createAnchorElement();
		el.href = "#";
		el.appendChild(document.createTextNode(text));
		el.addEventListener("click", function(e:MouseEvent) {
			e.preventDefault();
			fn();
		});
		ctr.appendChild(el);
		out.appendChild(ctr);
		return ctr;
	}
	public static function addText(out:Element, text:String):Element {
		var ctr = document.createDivElement();
		ctr.classList.add("plaintext");
		ctr.appendChild(document.createTextNode(text));
		out.appendChild(ctr);
		return ctr;
	}
	public static function createShellAnchor(url:String, label:String) {
		var a = document.createAnchorElement();
		a.href = url;
		a.target = "_blank";
		a.onclick = function(_) {
			electron.Shell.openExternal(url);
			return false;
		};
		a.appendChild(document.createTextNode(label));
		return a;
	}
	public static function createFuncAnchor(label:String, func:js.html.Event->Void) {
		var a = document.createAnchorElement();
		a.href = "javascript:void(0)";
		a.target = "_blank";
		a.onclick = function(e) {
			func(e);
			return false;
		};
		a.appendChild(document.createTextNode(label));
		return a;
	}
	public static function addWiki(to:Element, url:String, label:String = "wiki") {
		var lb:Element = to.querySelector("legend");
		if (lb == null) lb = to.querySelector("label");
		if (lb == null) lb = to;
		lb.appendChild(document.createTextNode(" ("));
		lb.appendChild(createShellAnchor(url, label));
		lb.appendChild(document.createTextNode(")"));
	}
	public static function createValidIdFromString(str:String) {
		//Lower case everything
		str = str.toLowerCase();
		//Make alphanumeric (removes all other characters)
		var alphanumeric = ~/[^a-z0-9_\s-]/g;
		str = alphanumeric.replace(str, "");
		//Clean up multiple dashes or whitespaces
		var dashes = ~/[\s-]+/g;
		str = dashes.replace(str, "");
		//Convert whitespaces and underscore to dash
		var whitespace = ~/[\s_]/g;
		str = whitespace.replace(str, "");
		return str;
	}
	public static function open() {
		var kind = file.kind.misc.KPreferences.inst;
		for (tab in ChromeTabs.getTabs()) {
			if (tab.gmlFile.kind == kind) {
				tab.click();
				return;
			}
		}
		kind.create("Preferences", null, null, null);
	}
	public static function save() {
		FileWrap.writeConfigSync("config", path, current);
	}
	public static function load() {
		var pref:PrefData = null;
		try {
			pref = FileWrap.readConfigSync("config", path);
		} catch (e:Dynamic) {
			console.error("Error loading preferences: ", e);
		}
		// migrations:
		if (pref != null) {
			if (pref.compMatchMode == null && pref.compExactMatch != null) {
				pref.compMatchMode = pref.compExactMatch ? PrefMatchMode.StartsWith : PrefMatchMode.AceSmart;
			}
		}
		// default settings:
		var def:PrefData = {
			theme: "dark",
			ukSpelling: false,
			compMatchMode: PrefMatchMode.StartsWith,
			argsMagic: true,
			argsFormat: "@param",
			argsStrict: false,
			importMagic: true,
			allowImportUndo: false,
			coroutineMagic: true,
			lambdaMagic: true,
			hyperMagic: true,
			mfuncMagic: true,
			fileSessionTime: 7,
			projectSessionTime: 14,
			singleClickOpen: false,
			taskbarOverlays: false,
			assetThumbs: true,
			clearAssetThumbsOnRefresh: true,
			showGMLive: Everywhere,
			codeLiterals: false,
			ctrlWheelFontSize: true,
			fileChangeAction: Ask,
			closeTabsOnFileDeletion: true,
			backupCount: { v1: 2, v2: 0, live: 0 },
			recentProjectCount: 16,
			tabSize: 4,
			tabSpaces: true,
			detectTab: true,
			eventOrder: 1,
			extensionAPIOrder: 1,
			tooltipDelay: 350,
			tooltipKeyboardDelay: 0,
			tooltipKind: Custom,
			linterPrefs: {},
		};
		// load/merge defaults:
		var doSave = false;
		if (pref == null) {
			pref = def;
			doSave = true;
		} else NativeObject.forField(def, function(k) {
			if (Reflect.field(pref, k) == null) {
				Reflect.setField(pref, k, Reflect.field(def, k));
				doSave = true;
			}
		});
		//
		current = pref;
		if (doSave) save();
		//
		if (pref.theme != null) Theme.current = pref.theme;
		GmlAPI.ukSpelling = pref.ukSpelling;
	}
	public static function init() {
		var isMac:Bool;
		var ep = untyped window.process;
		if (ep == null) {
			var np = Main.window.navigator.platform;
			isMac = np != null && np.toLowerCase().indexOf("mac") >= 0;
		} else isMac = ep.platform == "darwin";
		FileWrap.isMac = isMac;
		load();
	}
	public static function hookSetOption(obj:Dynamic):Void {
		if (obj.setOption_raw != null) return;
		obj.setOption_raw = obj.setOption;
		obj.setOption = function(key:String, val:Dynamic) {
			obj.setOption_raw(key, val);
			if (key == "tabSize" && val != current.tabSize) {
				current.tabSize = Std.parseInt(val);
				save();
			}
			if (key == "useSoftTabs" && val != current.tabSpaces) {
				current.tabSpaces = val;
				save();
			}
			if (Main.aceEditor != null) {
				var opts:DynamicAccess<Dynamic> = Main.aceEditor.getOptions();
				opts.remove("enableLiveAutocompletion");
				opts.remove("theme");
				opts.remove("enableSnippets");
				FileWrap.writeConfigSync("config", "aceOptions", cast opts);
				//Main.console.log("Ace settings saved.");
			}
		};
	}
	public static function bindEditor(editor:AceWrap) {
		// load Ace options:
		try {
			var opts:DynamicAccess<Dynamic> = cast FileWrap.readConfigSync("config", "aceOptions");
			if (opts != null) {
				opts.set("enableSnippets", true);
				opts.remove("mode");
				editor.setOptions(opts);
			}
		} catch (e:Dynamic) {
			console.error("Error loading Ace options: " + e);
		};
		editor.setOption("fixedWidthGutter", true);
		// flush Ace options on changes (usually only via Ctrl+,):
		hookSetOption(editor);
		hookSetOption(editor.renderer);
		if (editor.getOption("fontFamily") == null) {
			var font = FileWrap.isMac ? "Menlo, monospace" : "Consolas, Courier New, monospace";
			editor.setOption("fontFamily", font);
		}
	}
}
