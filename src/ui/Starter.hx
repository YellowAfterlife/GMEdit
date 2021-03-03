package ui;
import js.html.TextAreaElement;
import tools.ChainCall;
import ui.preferences.PrefData;
#if starter
import js.lib.Error;
import ui.Theme;
import haxe.Json;
import js.Browser.window;

/**
 * A lightweight (~25KB) application that loads your preferences
 * and theme before the actual GMEdit files start loading.
 * 
 * Prevents you from seeing GMEdit pop from default theme to selected one
 * if JS files take long enough to compile.
 * @author YellowAfterlife
 */
class Starter {
	public static var modulePath:String;
	public static var userPath:String;
	
	static function initAPI():Void {
		modulePath = untyped window.__dirname;
		if (modulePath == null) modulePath = ".";
		//
		var hasRequire = (cast window).require != null;
		inline function req(name:String):Dynamic {
			return (untyped require)(name);
		}
		inline function softReq<T>(name:String, ?def:T):T {
			return hasRequire ? req(name) : def;
		}
		var dynWindow:Dynamic = window;
		dynWindow.__themeData = {};
		dynWindow.Electron_FS = softReq("fs", FileSystemBrowser);
		//
		var electron = softReq("electron");
		if (electron != null) {
			userPath = electron.remote.app.getPath("userData") + "/GMEdit";
		}
		dynWindow.Electron = electron;
	}
	
	static function initAce():Void {
		var text:String = null;
		var name = "aceOptions";
		if (FileSystemMin.canSync) {
			var full = userPath + "/config/" + name + ".json";
			if (FileSystemMin.existsSync(full)) try {
				text = FileSystemMin.readTextFileSync(full);
			} catch (_:Dynamic) {}
		} else text = window.localStorage.getItem(name);
		if (text == null) return;
		//
		var aceData:Dynamic = try {
			Json.parse(text);
		} catch (_:Dynamic) return;
		var log:TextAreaElement = cast window.document.getElementById("source");
		var ff = aceData.fontFamily; if (ff != null) log.style.fontFamily = ff;
		var fs = aceData.fontSize; if (fs != null) log.style.fontSize = fs + "px";
	}
	
	static function initPreferences():Void {
		var prefName = Preferences.path;
		var prefText:String = null;
		if (FileSystemMin.canSync) {
			var full = userPath + "/config/" + prefName + ".json";
			if (FileSystemMin.existsSync(full)) try {
				prefText = FileSystemMin.readTextFileSync(full);
			} catch (_:Dynamic) {}
		} else prefText = window.localStorage.getItem(prefName);
		//
		var pref:PrefData = null;
		if (prefText != null) try {
			pref = Json.parse(prefText);
		} catch (_:Dynamic) {}
		//
		if (pref != null && pref.theme != null) {
			Theme.set(pref.theme, ready);
		} else ready();
	}
	
	static function ready() {
		var files:Array<String> = (cast window).__starterFiles;
		(cast window).__starterFiles = null;
		var log:TextAreaElement = cast window.document.querySelector("#source");
		function addScript(path:String, fn:String->Void) {
			Console.log('Loading $path...');
			log.value += 'Loading $path... ';
			function then(status:String):Void {
				log.value += status + "!\n";
				window.setTimeout(function() fn(null), 1);
			}
			window.setTimeout(function() {
				var scr = window.document.createScriptElement();
				scr.type = "text/javascript";
				scr.charset = "utf-8";
				scr.async = true;
				scr.addEventListener("load", function(_) {
					then("OK");
				});
				scr.addEventListener("error", function(e) {
					Console.error(e);
					then("error");
				});
				scr.src = path;
				window.document.body.appendChild(scr);
			}, 1);
		}
		var cc = new ChainCall();
		for (file in files) cc.call(addScript, file, function(_) {});
		cc.call(function(_, _) {
			Console.log("ready!");
		}, null, function(_) {});
	}
	public static function main() {
		(cast window).__hasStarter = true;
		try {
			initAPI();
			initAce();
			initPreferences();
		} catch (x:Dynamic) {
			Console.error(x);
			if (ElectronMin != null) try {
				var w = ElectronMin.remote.getCurrentWindow();
				if (!w.isDevToolsOpened()) {
					w.openDevTools();
				}
			} catch (_:Dynamic) {}
			ready();
		}
	}
}
@:native("Electron") extern class ElectronMin {
	static var remote:Dynamic;
}
@:native("Electron_FS") extern class FileSystemMin {
	public static function existsSync(path:String):Bool;
	/** Whether synchronous functions are supported */
	public static var canSync(get, never):Bool;
	private static inline function get_canSync():Bool {
		return existsSync != null;
	}
	
	static function readFile(path:String, enc:String, callback:Error->Dynamic->Void):Void;
	static inline function readTextFile(path:String, callback:Error->String->Void):Void {
		readFile(path, "utf8", cast callback);
	}
	static inline function readJsonFile<T:{}>(path:String, callback:Error->T->Void):Void {
		readFile(path, "utf8", function(e:Error, d:Dynamic) {
			if (d != null) try {
				d = Json.parse(d);
			} catch (x:Dynamic) {
				d = null; e = x;
			}
			callback(e, d);
		});
	}
	
	public static function readFileSync(path:String, ?enc:String):Dynamic;
	public static inline function readTextFileSync(path:String):String {
		return readFileSync(path, "utf8");
	}
	public static inline function readJsonFileSync(path:String):Dynamic {
		return Json.parse(readTextFileSync(path));
	}
}
@:keep class FileSystemBrowser {
	static function readFile(path:String, enc:String, callback:Error->Dynamic->Void):Void {
		var http = new haxe.http.HttpJs(path);
		http.onError = function(msg) callback(new Error(msg), null);
		http.onData = function(data) callback(null, data);
		http.request();
	}
}
#end