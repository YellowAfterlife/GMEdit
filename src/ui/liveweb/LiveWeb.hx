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
import file.kind.gml.KGmlScript;
using tools.HtmlTools;
import Main.document;
import Main.window;

/**
 * Helpers for GMLive-web
 * @author YellowAfterlife
 */
class LiveWeb {
	//
	public static function getPairs(?post:Bool):Array<LiveWebTab> {
		var out = [];
		function proc(file:GmlFile) {
			if (!Std.is(file.kind, KGmlScript)) return;
			var edit:EditCode = cast file.editor;
			var val = edit.session.getValue();
			if (post) {
				var pair = edit.postpImport(val);
				if (pair == null) return;
				val = pair.val;
				val = (cast file.kind:KGmlScript).postproc_1(edit, val, pair.sessionChanged);
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
	public static function setPairs(pairs:Array<LiveWebTab>):Void {
		for (tab in ChromeTabs.impl.tabEls) {
			ChromeTabs.impl.removeTab(tab);
		}
		var first = null;
		for (pair in pairs) {
			var path = pair.name;
			var code = pair.code;
			var file = new GmlFile(path, path, KGmlScript.inst, code);
			if (first == null) first = file;
			GmlFile.next = file;
			ChromeTabs.addTab(pair.name);
			GmlSeeker.runSync(path, code, "", KGmlScript.inst);
			var edit:EditCode = cast file.editor;
			edit.postpImport(edit.session.getValue());
			edit.session.bgTokenizer.start(0);
		}
		if (first != null) for (tab in ChromeTabs.impl.tabEls) {
			if (tab.gmlFile != first) continue;
			tab.click();
			break;
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
	static function postfixColors(s:String):String {
		if (!~/#define draw\b/g.match(s)) return s;
		if (~/\b(?:background_color|background_colour|draw_clear)\b/g.match(s)) return s;
		return "background_color = $F5F5F5; draw_set_color(0); // (legacy colors)\n" + s;
	}
	public static function readyUp() {
		if (isReady) return;
		isReady = true;
		var sp = getParams();
		var s:String;
		//
		if ((s = sp["mode"]) != null) {
			var mc = modeEl.onchange;
			modeEl.onchange = null;
			modeEl.value = s;
			if (modeEl.value == "") modeEl.value = "2d";
			modeEl.onchange = mc;
		}
		//
		if ((s = sp["tabs_lz"]) != null) {
			loadState(LZString.decompressFromEncodedURIComponent(s));
		} else if ((s = sp["tabs_64"]) != null) {
			loadState(Base64.decode(s));
		} else if ((s = sp["lzgml"]) != null) {
			try {
				s = LZString.decompressFromEncodedURIComponent(s);
				setPairs([{ name: "main", code: postfixColors(s) }]);
			} catch (x:Dynamic) {
				window.alert("Decompression error:\n" + x);
			}
		} else if ((s = sp["gml"]) != null) {
			try {
				s = Base64.decode(s);
				setPairs([{ name:"main", code: postfixColors(s) }]);
			} catch (x:Dynamic) {
				window.alert("Decode error:\n" + x);
			}
		} else loadState();
		Reflect.field(window, "lwRunBlank")();
	}
	
	public static function addTab(name:String, code:String) {
		for (tab in ChromeTabs.impl.tabEls) {
			if (tab.gmlFile.name == name) {
				window.alert("A tab with this name already exists.");
				return;
			}
		}
		var file = new GmlFile(name, name, KGmlScript.inst, code);
		GmlFile.openTab(file);
		parsers.GmlSeeker.runSync(name, name, code, KGmlScript.inst);
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
		Reflect.setField(window, "aceGetPairs", getPairs);
		Reflect.setField(window, "aceSetPairs", setPairs);
		Reflect.setField(window, "aceTabFlush", function() {
			for (tab in ChromeTabs.impl.tabEls) {
				var file = tab.gmlFile;
				file.save();
			}
			saveState();
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
			AceStatusBar.setStatusHint(msg);
			AceStatusBar.ignoreUntil = window.performance.now() + AceStatusBar.delayTime + 50;
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
			var hint = AceStatusBar.statusHint;
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
			AceStatusBar.ignoreUntil = window.performance.now() + AceStatusBar.delayTime + 50;
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
		modeEl = document.querySelectorAuto("#mode");
		modeEl.onchange = function(_) {
			if (modeEl.value != "") {
				Reflect.field(window, "lwModeChanged")();
			}
		};
		//
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
