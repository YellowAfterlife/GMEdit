package ui;
import gml.file.GmlFile;
import haxe.Json;
import js.html.SelectElement;
import js.html.TextAreaElement;
import tools.Base64;
import tools.Dictionary;
using tools.HtmlTools;
import Main.document;
import Main.window;

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
	static inline var lsPairs = "liveweb-state";
	static inline var lsMode = "liveweb-mode";
	static var modeEl:SelectElement;
	
	//
	public static function saveState() {
		window.localStorage.setItem(lsPairs, Json.stringify(getPairs()));
		window.localStorage.setItem(lsMode, modeEl.value);
	}
	public static function loadState(?raw:String) {
		if (raw == null) {
			raw = window.localStorage.getItem(lsPairs);
			modeEl.value = window.localStorage.getItem(lsMode);
			if (modeEl.value == "") modeEl.value = "2d";
		}
		if (raw != null && raw != "") try {
			setPairs(Json.parse(raw));
		} catch (x:Dynamic) {
			Main.console.error("Couldn't load tabs", x);
		}
	}
	
	static function getParams():Dictionary<String> {
		var out = new Dictionary();
		var search = window.location.search;
		var p = search.indexOf("?");
		if (search == "" || p < 0) return out;
		var pairs = search.substring(p + 1).split("&");
		for (pair in pairs) {
			p = pair.indexOf("=");
			if (p >= 0) {
				out.set(pair.substring(0, p), pair.substring(p + 1));
			} else out.set(pair, "");
		}
		return out;
	}
	
	//
	static var isReady = false;
	public static function readyUp() {
		if (isReady) return;
		isReady = true;
		var sp = getParams();
		var s:String;
		//
		if ((s = sp["mode"]) != null) {
			modeEl.value = s;
			if (modeEl.value == "") modeEl.value = "2d";
		}
		//
		if ((s = sp["tabs_lz"]) != null) {
			loadState(LZString.decompressFromEncodedURIComponent(s));
		} else if ((s = sp["tabs_64"]) != null) {
			loadState(Base64.decode(s));
		} else if ((s = sp["lzgml"]) != null) {
			try {
				setPairs([{name:"main", code:LZString.decompressFromEncodedURIComponent(s)}]);
			} catch (x:Dynamic) {
				window.alert("Decompression error:\n" + x);
			}
		} else if ((s = sp["gml"]) != null) {
			try {
				setPairs([{name:"main", code:LZString.decompressFromEncodedURIComponent(s)}]);
			} catch (x:Dynamic) {
				window.alert("Decode error:\n" + x);
			}
		} else loadState();
	}
	
	//
	public static function init() {
		#if lwedit
		Reflect.setField(window, "aceGetPairs", getPairs);
		Reflect.setField(window, "aceSetPairs", setPairs);
		Reflect.setField(window, "aceTabFlush", function() {
			for (tab in ChromeTabs.impl.tabEls) {
				tab.gmlFile.markClean();
			}
			saveState();
		});
		//
		modeEl = document.querySelectorAuto("#mode");
		document.getElementById("share").onclick = function() {
			var params = ["mode=" + modeEl.value];
			//
			var src = Json.stringify(getPairs());
			var lzs = "tabs_lz=" + LZString.compressToEncodedURIComponent(src);
			var b64 = "tabs_64=" + Base64.encode(src);
			params.push(lzs.length < b64.length ? lzs : b64);
			//
			var url = "https://yal.cc/r/gml/?" + params.join("&");
			var size = url.length;
			var sizeStr:String;
			if (size >= 10000) {
				sizeStr = (Std.int((size / 1024) * 100) * 0.01) + "KB";
			} else sizeStr = size + "B";
			//
			var textarea = document.querySelectorAuto("#lw_share_code", TextAreaElement);
			document.querySelector("#lw_share_size").setInnerText(sizeStr);
			textarea.value = url;
			document.querySelector("#lw_share").style.display = "";
			textarea.select();
		}
		#end
	}
}
@:native("LZString") extern class LZString {
	public static function compressToEncodedURIComponent(s:String):String;
	public static function decompressFromEncodedURIComponent(s:String):String;
}
typedef LiveWebTab = { name:String, code:String };
