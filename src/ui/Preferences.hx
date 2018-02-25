package ui;
import ace.AceWrap;
import electron.FileSystem;
import electron.Menu;
import gml.GmlAPI;
import haxe.Json;
import haxe.io.Path;
import js.html.Element;
import js.html.InputElement;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.Window;
import Main.document;
import tools.Dictionary;
import tools.NativeObject;
using tools.HtmlTools;

/**
 * User preferences are managed here!
 * Currently everything is just dumped into LocalStorage in JSON format.
 * @author YellowAfterlife
 */
class Preferences {
	public static var path:String = "user-preferences";
	public static var current:PrefData;
	public static var element:Element;
	public static var subMenu:Element;
	static function setMenu(el:Element) {
		if (subMenu != el) {
			if (subMenu != null) element.removeChild(subMenu);
			subMenu = el;
			element.appendChild(el);
		}
		return el;
	}
	//
	private static function addRadios(out:Element, legend:String, curr:String, names:Array<String>, fn:String->Void) {
		var fs = document.createFieldSetElement();
		fs.classList.add("radios");
		var lg = document.createLegendElement();
		lg.innerText = legend;
		fs.appendChild(lg);
		for (name in names) {
			var rad = document.createInputElement();
			rad.type = "radio";
			rad.name = legend;
			rad.value = name;
			rad.addEventListener("change", function(_) {
				fn(name);
			});
			if (curr == name) rad.checked = true;
			var lb = document.createLabelElement();
			lb.htmlFor = name;
			lb.appendChild(document.createTextNode(name));
			fs.appendChild(rad);
			fs.appendChild(lb);
			fs.appendChild(document.createBRElement());
		}
		out.appendChild(fs);
	}
	private static function addDropdown(out:Element, legend:String, curr:String, names:Array<String>, fn:String->Void) {
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
	private static function addCheckbox(out:Element, legend:String, curr:Bool, fn:Bool->Void):Element {
		var ctr = document.createDivElement();
		ctr.classList.add("checkbox");
		var cb = document.createInputElement();
		cb.type = "checkbox";
		cb.checked = curr;
		cb.name = legend;
		cb.addEventListener("change", function(_) {
			fn(cb.checked);
		});
		ctr.appendChild(cb);
		var lb = document.createLabelElement();
		lb.htmlFor = legend;
		lb.appendChild(document.createTextNode(legend));
		ctr.appendChild(lb);
		out.appendChild(ctr);
		return ctr;
	}
	private static function addInput(out:Element, legend:String, curr:String, fn:String->Void):Element {
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
	private static function addIntInput(out:Element, legend:String, val:Int, fn:Int->Void):Element {
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
	private static function addFloatInput(out:Element, legend:String, val:Float, fn:Float->Void):Element {
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
	private static function addButton(out:Element, text:String, fn:Void->Void):Element {
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
	private static function addText(out:Element, text:String):Element {
		var ctr = document.createDivElement();
		ctr.classList.add("plaintext");
		ctr.appendChild(document.createTextNode(text));
		out.appendChild(ctr);
		return ctr;
	}
	private static function addWiki(to:Element, url:String, label:String = "wiki") {
		var lb = to.querySelector("label");
		lb.appendChild(document.createTextNode(" ("));
		var a = document.createAnchorElement();
		a.href = url;
		a.target = "_blank";
		a.onclick = function(_) {
			electron.Shell.openExternal(url);
			return false;
		};
		a.appendChild(document.createTextNode(label));
		lb.appendChild(a);
		lb.appendChild(document.createTextNode(")"));
	}
	//
	private static var menuMain:Element;
	private static function buildMain() {
		var out = document.createElement("div");
		var el:Element;
		//
		var themeList = ["default"];
		for (name in FileSystem.readdirSync(Main.relPath(Theme.path))) {
			if (name == "default") continue;
			var full = Path.join([Main.modulePath, Theme.path, name, "config.json"]);
			if (FileSystem.existsSync(full)) themeList.push(name);
		}
		addRadios(out, "Theme", current.theme, themeList, function(theme) {
			current.theme = theme;
			Theme.current = theme;
			save();
		});
		//
		el = addCheckbox(out, "Use `#args` magic", current.argsMagic, function(z) {
			current.argsMagic = z;
			save();
		});
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-%23args-magic");
		el.title = "Allows writing `#args a, b` instead of `var a = argument0, b = argument1`.";
		//
		el = addCheckbox(out, "Use `#import` magic", current.importMagic, function(z) {
			current.importMagic = z;
			save();
		});
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-%23import-magic");
		el.title = "Allows setting up rules for shortening names per-script.";
		//
		addCheckbox(out, "Allow undo-ing `#import`", current.allowImportUndo, function(z) {
			current.allowImportUndo = z;
			save();
		}).title = "Allows undoing name changes made after changing #import rules."
			+ "\nMakes it easier to break code, so be careful.";
		//
		el = addCheckbox(out, "Use coroutine magic", current.coroutineMagic, function(z) {
			current.coroutineMagic = z;
			save();
		});
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-coroutine-magic");
		//
		var optGMLive = ["Hide", "Show on items", "Show everywhere"];
		el = addDropdown(out, "Show GMLive badges", optGMLive[current.showGMLive], optGMLive, function(v) {
			var v0:PrefGMLive = current.showGMLive;
			var v1:PrefGMLive = optGMLive.indexOf(v);
			if (v0 == v1) return;
			current.showGMLive = v1;
			if (gml.Project.current.hasGMLive) {
				if (v0.isActive() != v1.isActive()) {
					for (el in TreeView.element.querySelectorEls(".item")) {
						if (v1.isActive()) {
							var data = parsers.GmlSeekData.map[el.getAttribute(TreeView.attrPath)];
							if (data != null) {
								if (data.hasGMLive) {
									el.setAttribute(GMLive.attr, "");
								} else el.removeAttribute(GMLive.attr);
							}
						} else el.removeAttribute(GMLive.attr);
					}
				}
				GMLive.updateAll(true);
			}
			save();
		});
		addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/GMLive-in-GMEdit");
		//
		addCheckbox(out, "UK spelling", current.ukSpelling, function(z) {
			current.ukSpelling = z;
			GmlAPI.ukSpelling = z;
			GmlAPI.init();
			save();
		}).title = "Displays UK versions of function/variable names (e.g. draw_set_colour) in auto-completion when available.";
		addCheckbox(out, "Show asset thumbnails", current.assetThumbs, function(z) {
			current.assetThumbs = z;
			save();
			gml.Project.current.reload();
		}).title = "Loads and displays the assigned sprites as object thumbnails in resource tree.";
		//
		addFloatInput(out, "Keep file sessions for (days):", current.fileSessionTime, function(v) {
			current.fileSessionTime = v; save();
		});
		//
		addFloatInput(out, "Keep project sessions for (days):", current.projectSessionTime, function(v) {
			current.projectSessionTime = v; save();
		});
		//
		addButton(out, "Backup settings", function() {
			setMenu(menuBackups);
		});
		addButton(out, "Code Editor Settings", function() {
			AceWrap.loadModule("ace/ext/settings_menu", function(module) {
				module.init(Main.aceEditor);
				untyped Main.aceEditor.showSettingsMenu();
			});
		});
		//
		addButton(out, "Close", function() {
			element.style.display = "none";
		});
		//
		return out;
	}
	//
	private static var menuBackups:Element;
	private static function buildBackups() {
		var out = document.createElement("div");
		//
		addText(out, "Values are numbers of backup copies per file."
			+ " See wiki for more information.");
		addIntInput(out, "for GMS1 projects", current.backupCount.v1, function(n) {
			current.backupCount.v1 = n; save();
		});
		addIntInput(out, "for GMS2 projects", current.backupCount.v2, function(n) {
			current.backupCount.v2 = n; save();
		});
		addIntInput(out, "for other projects", current.backupCount.live, function(n) {
			current.backupCount.live = n; save();
		});
		//
		addButton(out, "Back", function() {
			setMenu(menuMain);
		});
		//
		return out;
	}
	//
	private static function build() {
		element = document.querySelector("#preferences-window");
		menuMain = buildMain();
		menuBackups = buildBackups();
	}
	public static function open() {
		if (element == null) build();
		if (element.style.display == "none") {
			setMenu(menuMain);
			element.style.display = "";
		} else element.style.display = "none";
	}
	public static function save() {
		Main.window.localStorage.setItem(path, Json.stringify(current));
	}
	public static function load() {
		var pref:PrefData = null;
		try {
			var data = Main.window.localStorage.getItem(path);
			pref = Json.parse(data);
		} catch (_:Dynamic) { }
		// default settings:
		var def:PrefData = {
			theme: "dark",
			ukSpelling: false,
			argsMagic: true,
			importMagic: true,
			coroutineMagic: true,
			allowImportUndo: false,
			fileSessionTime: 7,
			projectSessionTime: 14,
			assetThumbs: true,
			showGMLive: Everywhere,
			backupCount: { v1: 2, v2: 0, live: 0 },
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
		if (doSave) save();
		//
		if (pref.theme != null) Theme.current = pref.theme;
		GmlAPI.ukSpelling = pref.ukSpelling;
		//
		current = pref;
	}
	public static function init() {
		load();
	}
	public static function initEditor() {
		// load Ace options:
		try {
			var text = Main.window.localStorage.getItem("aceOptions");
			if (text != null) Main.aceEditor.setOptions(Json.parse(text));
		} catch (_:Dynamic) { };
		// flush Ace options on changes (usually only via Ctrl+,):
		var editor = Main.aceEditor;
		var origSetOption = editor.setOption;
		untyped editor.setOption = function(key, val) {
			origSetOption(key, val);
			var opts:Dictionary<Dynamic> = Main.aceEditor.getOptions();
			opts.remove("enableLiveAutocompletion");
			opts.remove("theme");
			Main.window.localStorage.setItem("aceOptions", Json.stringify(opts));
		};
		if (editor.getOption("fontFamily") == null) {
			var font = switch (untyped process.platform) {
				case "darwin": "Menlo, monospace";
				default: "Consolas, Courier New, monospace";
			}
			editor.setOption("fontFamily", font);
		}
	}
}
typedef PrefData = {
	theme:String,
	ukSpelling:Bool,
	fileSessionTime:Float,
	projectSessionTime:Float,
	argsMagic:Bool,
	importMagic:Bool,
	allowImportUndo:Bool,
	coroutineMagic:Bool,
	assetThumbs:Bool,
	showGMLive:PrefGMLive,
	backupCount:{ v1:Int, v2:Int, live:Int },
}
@:enum abstract PrefGMLive(Int) from Int to Int {
	var Nowhere = 0;
	var ItemsOnly = 1;
	var Everywhere = 2;
	public inline function isActive():Bool {
		return this > 0;
	}
}
