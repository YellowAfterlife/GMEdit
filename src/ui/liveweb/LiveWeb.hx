package ui.liveweb;
import ace.AceStatusBar;
import ace.AceWrap;
import ace.extern.*;
import editors.EditCode;
import gml.file.GmlFile;
import gml.*;
import parsers.*;
import haxe.Json;
import js.html.KeyboardEvent;
import js.html.SelectElement;
import js.html.TextAreaElement;
import js.lib.RegExp;
import tools.Base64;
import tools.Dictionary;
import ui.ChromeTabs;
import ui.liveweb.KLiveWeb;
import ui.liveweb.LiveWebAPI;
import ui.liveweb.LiveWebState;
using tools.HtmlTools;
import Main.document;
import Main.window;

/**
 * Helpers for GMLive-web
 * @author YellowAfterlife
 */
#if (gmedit.live && !gmedit.mini)
class LiveWeb {
	//
	public static var modeEl:SelectElement = document.querySelectorAuto("#mode");
	public static var verEl:SelectElement = document.querySelectorAuto("#runtime-ver");
	public static var api:LiveWebAPI;
	
	//
	static var isReady = false;
	public static function readyUp() {
		LiveWebState.finish();
		if (isReady) return;
		isReady = true;
		api.run({}, function(_, _){});
	}
	
	//
	public static function init() {
		#if gmedit.live
		var init:LiveWebInit = {};
		init.aceEditor = Main.aceEditor;
		init.isElectron = electron.Electron.isAvailable();
		init.gameFrame = cast document.getElementById("game");
		api = Reflect.field(window, "LiveWebAPI");
		api.init(init);
		//
		function updateVersion() {
			var v2 = verEl.value == "GMS2";
			var ver = v2 ? GmlVersion.v2 : GmlVersion.v1;
			GmlAPI.version = ver;
			Project.current.version = ver;
			api.setVersion(v2 ? 20 : 14, modeEl.value);
			api.resyncAPI();
			api.run({}, function(e, js) {});
		}
		modeEl.onchange = function(_) {
			if (modeEl.value != "") updateVersion();
		};
		verEl.onchange = function(_) {
			if (verEl.value != "") updateVersion();
		};
		//
		var rxFirstLine = new RegExp("^//(.+)");
		function run(reload:Bool) {
			for (tab in ChromeTabs.impl.tabEls) {
				var file = tab.gmlFile;
				file.save();
			}
			LiveWebState.save();
			//
			for (tab in ChromeTabs.impl.tabEls) {
				var es = tab.gmlFile.getAceSession();
				if (es == null) continue;
				var mk = es.gmlErrorMarker;
				if (mk == null) continue;
				es.removeMarker(mk);
				es.gmlErrorMarker = null;
				es.clearAnnotations();
			}
			//
			api.run({
				reload: reload,
				sources: LiveWebState.getPairs(true),
			}, function(e:LiveWebError, js:String) {
				if (e == null) {
					var mt = rxFirstLine.exec(js);
					var msg = mt != null ? mt[0] : "Compiled";
					var statusBar = Main.aceEditor.statusBar;
					statusBar.setText(msg);
					statusBar.ignoreUntil = window.performance.now() + statusBar.delayTime + 50;
					for (tab in ChromeTabs.impl.tabEls) {
						var es = tab.gmlFile.getAceSession();
						if (es == null) continue;
						es.clearAnnotations();
					}
				} else {
					LiveWebTools.showError(e);
				}
			});
		}
		//
		document.getElementById("refresh").onclick = function(_) run(false);
		document.getElementById("reload").onclick = function(_) run(true);
		document.getElementById("stop").onclick = function(_) api.stop();
		window.addEventListener("keydown", function(e:KeyboardEvent) {
			if (e.keyCode == 116 || (e.keyCode == 13 && e.ctrlKey)) {
				run(false);
				e.preventDefault();
				e.stopPropagation();
			}
		});
		document.getElementById("share").onclick = function() {
			var params = ["mode=" + modeEl.value, "ver=" + verEl.value];
			//
			var src = Json.stringify(LiveWebState.getPairs());
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
		LiveWebState.init();
		#end
	}
}
#end
