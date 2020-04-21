package ui.liveweb;
import ace.AceStatusBar;
import ace.AceWrap;
import ace.extern.*;
import editors.EditCode;
import gml.file.GmlFile;
import gml.*;
import parsers.*;
import haxe.Json;
import js.html.SelectElement;
import js.html.TextAreaElement;
import tools.Base64;
import tools.Dictionary;
import ui.ChromeTabs;
import ui.liveweb.KLiveWeb;
import ui.liveweb.LiveWebState;
using tools.HtmlTools;
import Main.document;
import Main.window;

/**
 * Helpers for GMLive-web
 * @author YellowAfterlife
 */
class LiveWeb {
	//
	public static var modeEl:SelectElement = document.querySelectorAuto("#mode");
	public static var verEl:SelectElement = document.querySelectorAuto("#runtime-ver");
	
	//
	static var isReady = false;
	public static function readyUp() {
		LiveWebState.finish();
		if (isReady) return;
		isReady = true;
		Reflect.field(window, "lwRunBlank")();
	}
	
	public static function addTab(name:String, code:String) {
		for (tab in ChromeTabs.impl.tabEls) {
			if (tab.gmlFile.name == name) {
				window.alert("A tab with this name already exists.");
				return;
			}
		}
		var file = new GmlFile(name, name, KLiveWeb.inst, code);
		GmlFile.openTab(file);
		GmlSeeker.runSync(name, name, code, KLiveWeb.inst);
	}
	
	public static function newTabDialog() {
		electron.Dialog.showPrompt("New tab name?", "", function(name) {
			if (name == null || name == "") return;
			addTab(name, "");
		});
	}
	
	//
	public static function init() {
		#if lwedit
		Reflect.setField(window, "aceGetPairs", LiveWebState.getPairs);
		Reflect.setField(window, "aceSetPairs", LiveWebState.setPairs);
		Reflect.setField(window, "aceTabFlush", function() {
			for (tab in ChromeTabs.impl.tabEls) {
				var file = tab.gmlFile;
				file.save();
			}
			LiveWebState.save();
		});
		Reflect.setField(window, "aceClearErrors", function() {
			for (tab in ChromeTabs.impl.tabEls) {
				var es = tab.gmlFile.getAceSession();
				if (es == null) continue;
				var mk = es.gmlErrorMarker;
				if (mk == null) continue;
				es.removeMarker(mk);
				es.gmlErrorMarker = null;
				es.clearAnnotations();
			}
		});
		Reflect.setField(window, "aceHintText", function(msg:String) {
			var statusBar = Main.aceEditor.statusBar;
			statusBar.setText(msg);
			statusBar.ignoreUntil = window.performance.now() + statusBar.delayTime + 50;
			for (tab in ChromeTabs.impl.tabEls) {
				var es = tab.gmlFile.getAceSession();
				if (es == null) continue;
				es.clearAnnotations();
			}
		});
		Reflect.setField(window, "aceHintError", function(path:String, pos:AcePos, msg:String) {
			var col = pos.column;
			var row = pos.row;
			//
			var hint = Main.aceEditor.statusBar.statusHint;
			hint.setInnerText(msg);
			hint.classList.add("active");
			hint.onclick = function(_) {
				if (GmlFile.current.path != path) {
					for (tab in ChromeTabs.impl.tabEls) {
						if (tab.gmlFile.path != path) continue;
						tab.click();
						break;
					}
					window.setTimeout(function() {
						Main.aceEditor.gotoLine0(row, col);
					});
				} else Main.aceEditor.gotoLine0(row, col);
			};
			var statusBar = Main.aceEditor.statusBar;
			statusBar.ignoreUntil = window.performance.now() + statusBar.delayTime + 50;
			//
			for (tab in ChromeTabs.impl.tabEls) {
				if (tab.gmlFile.path != path) continue;
				var session = tab.gmlFile.getAceSession();
				if (session == null) continue;
				var range = new AceRange(0, row, session.getLine(row).length, row);
				session.gmlErrorMarker = session.addMarker(range, "ace_error-line", "fullLine");
				session.setAnnotations([{
					row: row, column: col, type: "error", text: msg
				}]);
				break;
			}
		});
		//
		modeEl.onchange = function(_) {
			if (modeEl.value != "") {
				Reflect.field(window, "lwModeChanged")();
			}
		};
		//
		verEl.onchange = function(_) {
			if (verEl.value != "") {
				var v2 = verEl.value == "GMS2";
				var ver = v2 ? GmlVersion.v2 : GmlVersion.v1;
				GmlAPI.version = ver;
				Project.current.version = ver;
				Reflect.field(window, "lwSetVersion")(v2);
			}
		};
		//
		document.getElementById("share").onclick = function() {
			var params = ["mode=" + modeEl.value];
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
