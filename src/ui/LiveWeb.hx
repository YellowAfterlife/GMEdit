package ui;
import gml.file.GmlFile;
import haxe.Json;

/**
 * Helpers for GMLive-web
 * @author YellowAfterlife
 */
class LiveWeb {
	//
	public static function getPairs():Array<LiveWebTab> {
		var out = [];
		for (tab in ChromeTabs.impl.tabEls) {
			var file = tab.gmlFile;
			out.push({
				name: file.name,
				code: file.getAceSession().getValue(),
			});
		}
		return out;
	}
	public static function setPairs(pairs:Array<LiveWebTab>):Void {
		for (tab in ChromeTabs.impl.tabEls) {
			ChromeTabs.impl.removeTab(tab);
		}
		for (pair in pairs) {
			var path = pair.name;
			var code = pair.code;
			GmlFile.next = new GmlFile(path, path, Normal, code);
			ChromeTabs.addTab(pair.name);
			parsers.GmlSeeker.runSync(path, code, "");
		}
	}
	
	//
	static inline var lskey = "liveweb-state";
	public static function saveState() {
		Main.window.localStorage.setItem(lskey, Json.stringify(getPairs()));
	}
	public static function loadState() {
		var raw = Main.window.localStorage.getItem(lskey);
		if (raw != null && raw != "") try {
			setPairs(Json.parse(raw));
		} catch (x:Dynamic) {
			Main.console.error("Couldn't load tabs", x);
		}
	}
	public static function init() {
		Reflect.setField(Main.window, "aceGetPairs", getPairs);
		Reflect.setField(Main.window, "aceSetPairs", setPairs);
		Reflect.setField(Main.window, "aceTabFlush", function() {
			for (tab in ChromeTabs.impl.tabEls) {
				tab.gmlFile.markClean();
			}
			saveState();
		});
	}
}
typedef LiveWebTab = { name:String, code:String };
