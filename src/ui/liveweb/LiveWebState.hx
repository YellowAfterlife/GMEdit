package ui.liveweb;
import editors.EditCode;
import electron.FileSystem;
import electron.FileWrap;
import gml.GmlAPI;
import gml.GmlVersion;
import gml.file.GmlFile;
import haxe.Json;
import parsers.GmlSeeker;
import tools.Base64;
import tools.Dictionary;
import ui.WelcomePage;
using tools.HtmlTools;
/**
 * ...
 * @author YellowAfterlife
 */
#if gmedit.live
class LiveWebState {
	static inline var lsPairs = "liveweb-state";
	static inline var lsMode = "liveweb-mode";
	static inline var lsVersion = "liveweb-version";
	
	static function getParams():Dictionary<String> {
		var out = new Dictionary();
		var search = Main.window.location.search;
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
	
	public static function getPairs(?post:Bool):Array<LiveWebTab> {
		var out = [];
		function proc(file:GmlFile) {
			if (!Std.is(file.kind, KLiveWeb)) return;
			var fkind:KLiveWeb = cast file.kind;
			var edit:EditCode = file.codeEditor;
			var val = edit.session.getValue();
			if (post) {
				var pair = edit.postpImport(val);
				if (pair == null) return;
				val = pair.val;
				val = fkind.postproc_1(edit, val, pair.sessionChanged);
			}
			out.push({
				name: file.name,
				code: val,
			});
		}
		for (tab in ChromeTabs.impl.tabEls) proc(tab.gmlFile);
		if (ChromeTabs.impl.tabEls.length == 0) proc(GmlFile.current);
		return out;
	}
	public static function addCodeTab(path:String, code:String) {
		var file = new GmlFile(path, path, KLiveWeb.inst, code);
		GmlFile.next = file;
		ChromeTabs.addTab(path);
		GmlSeeker.runSync(path, code, "", KLiveWeb.inst);
		var edit:EditCode = cast file.editor;
		edit.postpImport(edit.session.getValue());
		edit.session.bgTokenizer.start(0);
		return file;
	}
	public static function setPairs(pairs:Array<LiveWebTab>):Void {
		var first = null;
		for (pair in pairs) {
			var path = pair.name;
			var code = pair.code;
			var file = addCodeTab(path, code);
			if (first == null) first = file;
		}
		if (first != null) for (tab in ChromeTabs.impl.tabEls) {
			if (tab.gmlFile != first) continue;
			tab.click();
			break;
		}
	}
	
	public static function save() {
		if (FileSystem.canSync) {
			var json:LiveWebStateImpl = {
				pairs: getPairs(),
				#if !gmedit.mini
				mode: LiveWeb.modeEl.value,
				version: LiveWeb.verEl.value
				#end
			};
			FileWrap.writeConfigSync("session", "liveweb", json);
		} else {
			Main.window.localStorage.setItem(lsPairs, Json.stringify(getPairs()));
			#if !gmedit.mini
			Main.window.localStorage.setItem(lsMode, LiveWeb.modeEl.value);
			Main.window.localStorage.setItem(lsVersion, LiveWeb.verEl.value);
			#end
		}
	}
	
	static function postfixColors(s:String):String {
		if (!~/#define draw\b/g.match(s)) return s;
		if (~/\b(?:background_color|background_colour|draw_clear)\b/g.match(s)) return s;
		return "background_color = $F5F5F5; draw_set_color(0); // (legacy colors)\n" + s;
	}
	
	static var tabPairs:Array<LiveWebTab> = null;
	/** Runs when we're done loading API. */
	public static function finish() {
		if (tabPairs == null) return;
		setPairs(tabPairs);
		tabPairs = null;
	}
	public static function init() {
		var isDefault = false;
		#if !gmedit.mini
		var sp = getParams();
		var s:String;
		//
		var modeEl = LiveWeb.modeEl;
		var verEl = LiveWeb.verEl;
		//
		if ((s = sp["tabs_lz"]) != null) {
			tabPairs = Json.parse(LZString.decompressFromEncodedURIComponent(s));
		} else if ((s = sp["tabs_64"]) != null) {
			tabPairs = Json.parse(Base64.decode(s));
		} else if ((s = sp["lzgml"]) != null) {
			s = LZString.decompressFromEncodedURIComponent(s);
			tabPairs = [{ name: "main", code: postfixColors(s) }];
		} else if ((s = sp["gml"]) != null) {
			s = Base64.decode(s);
			tabPairs = [{ name: "main", code: postfixColors(s) }];
		} else // ->
		#end
		{
			isDefault = true;
			#if !gmedit.mini
			if (FileSystem.canSync) {
				try {
					var json:LiveWebStateImpl = FileWrap.readConfigSync("session", "liveweb");
				} catch (x:Dynamic) {
					tabPairs = null;
				}
			} else // ->
			#end
			{
				var ls = Main.window.localStorage;
				var pairsText = ls.getItem(lsPairs);
				if (pairsText == null || pairsText == "") {
					tabPairs = null;
				} else try {
					tabPairs = Json.parse(pairsText);
					#if !gmedit.mini
					modeEl.setSelectValueWithoutOnChange(ls.getItem(lsMode), "2d");
					verEl.setSelectValueWithoutOnChange(ls.getItem(lsVersion), "GMS1");
					#end
				} catch (x:Dynamic) {
					tabPairs = null;
				}
			}
			if (tabPairs == null) {
				#if !gmedit.mini
				modeEl.setSelectValueWithoutOnChange(null, "2d");
				verEl.setSelectValueWithoutOnChange(null, "GMS2");
				#end
				tabPairs = [{
					name: "Hello!",
					code: WelcomePage.lwText
				}];
			}
		}
		//
		#if gmedit.mini
		GmlAPI.version = GmlVersion.v2;
		#else
		if (!isDefault) {
			if ((s = sp["mode"]) != null) modeEl.setSelectValueWithoutOnChange(s, "2d");
			if ((s = sp["ver"]) != null) verEl.setSelectValueWithoutOnChange(s, "GMS1");
		}
		//
		var v2 = verEl.value == "GMS2";
		LiveWeb.api.setVersion(v2 ? 20 : 14, LiveWeb.modeEl.value);
		GmlAPI.version = v2 ? GmlVersion.v2 : GmlVersion.v1;
		#end
	}
}
@:native("LZString") extern class LZString {
	public static function compressToEncodedURIComponent(s:String):String;
	public static function decompressFromEncodedURIComponent(s:String):String;
}
typedef LiveWebTab = { name:String, code:String };
typedef LiveWebStateImpl = {
	pairs:Array<LiveWebTab>,
	#if !gmedit.mini
	mode:String,
	version:String
	#end
}
#end
