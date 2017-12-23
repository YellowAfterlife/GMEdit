package ui;
import electron.FileSystem;
import gml.GmlAPI;
import haxe.Json;
import haxe.io.Path;
import js.html.Element;
import js.html.Window;
import Main.document;

/**
 * ...
 * @author YellowAfterlife
 */
class Preferences {
	public static var path:String = "user-preferences";
	public static var current:PrefData;
	public static var element:Element;
	//
	private static function build(out:Element) {
		function addRadios(legend:String, current:String, names:Array<String>, fn:String->Void) {
			var fs = document.createFieldSetElement();
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
				if (current == name) rad.checked = true;
				var lb = document.createLabelElement();
				lb.htmlFor = name;
				lb.appendChild(document.createTextNode(name));
				fs.appendChild(rad);
				fs.appendChild(lb);
				fs.appendChild(document.createBRElement());
			}
			out.appendChild(fs);
		}
		function addCheckbox(legend:String, current:Bool, fn:Bool->Void) {
			var cb = document.createInputElement();
			cb.type = "checkbox";
			cb.checked = current;
			cb.name = legend;
			cb.addEventListener("change", function(_) {
				fn(cb.checked);
			});
			out.appendChild(cb);
			var lb = document.createLabelElement();
			lb.htmlFor = legend;
			lb.appendChild(document.createTextNode(legend));
			out.appendChild(lb);
		}
		//
		var themeList = ["default"];
		for (name in FileSystem.readdirSync(Main.relPath(Theme.path))) {
			if (name == "default") continue;
			var full = Path.join([Main.modulePath, Theme.path, name, "config.json"]);
			if (FileSystem.existsSync(full)) themeList.push(name);
		}
		addRadios("Theme", current.theme, themeList, function(theme) {
			current.theme = theme;
			Theme.current = theme;
			save();
		});
		addCheckbox("UK spelling", current.ukSpelling, function(z) {
			trace(z);
			current.ukSpelling = z;
			GmlAPI.ukSpelling = z;
			GmlAPI.init();
			save();
		});
	}
	public static function open() {
		if (element == null) {
			element = document.querySelector("#preferences-window");
			build(element);
		}
		element.style.display = element.style.display != "" ? "" : "none";
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
		if (pref == null) {
			pref = { theme: "dark" };
			save();
		}
		//
		if (pref.theme != null) Theme.current = pref.theme;
		GmlAPI.ukSpelling = pref.ukSpelling;
		//
		current = pref;
	}
	public static function init() {
		Main.document.querySelector("#preferences-button")
			.addEventListener("click", function(_) open());
		load();
	}
}
typedef PrefData = {
	?theme:String,
	?ukSpelling:Bool,
}
