package electron;
import electron.Dialog.Electron_Dialog;
import electron.Menu;
#if !starter
import Main.window;
import js.Syntax;
import electron.FontScanner.FontScannerFallback;
import electron.extern.ElectronRemote;
import electron.extern.*;
import electron.ElectronMacros.*;

/*
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_API") extern class Electron {
	public static inline function isAvailable():Bool {
		return Electron != null;
	}
	public static var shell:Dynamic;
	public static var remote:ElectronRemote;
	public static var clipboard:Clipboard;
	public static var ipcRenderer:Dynamic;
	
	public static inline function init():Void {
		inline function load(hxname:String, ename:String):Void {
			untyped window[hxname] = require(ename);
		}
		inline function set(hxname:String, ref:Dynamic):Void {
			if (ref == null) throw "Can't find " + hxname;
			untyped window[hxname] = ref;
		}
		inline function blank(hxname:String) {
			untyped window[hxname] = null;
		}
		inline function req(name:String):Dynamic {
			return (untyped require)(name);
		}
		if (untyped window.require != null) {
			setExternTypeSafe(Electron, req("electron"));
			var ver = (cast window).parseInt((cast window).process.versions.electron);
			if (ver >= 14) {
				remote = req("@electron/remote");
			}
			setExternTypeSafe(FileSystem, req("fs"));
			setExternTypeSafe(Electron_Dialog, remote.dialog);
			Dialog.initWorkarounds();
			setExternTypeSafe(IPC, ipcRenderer);
			setExternTypeSafe(Shell, shell);
			setExternTypeSafe(Menu, remote.Menu);
			setExternTypeSafe(MenuItem, remote.MenuItem);
			setExternTypeSafe(AppTools, remote.app);
			setExternTypeSafe(BrowserWindow, remote.BrowserWindow);
			
			try {
				setExternType(FontScanner, req("./native/font-scanner/index.js"));
			} catch (x:Dynamic) {
				Main.console.warn("font-scanner failed to load: ", x);
				setExternType(FontScanner, cast FontScannerFallback);
			}
			
			function ensure(dir:String) {
				FileSystem.ensureDirSync(dir);
			}
			var path = AppTools.getPath("userData") + "/GMEdit";
			FileWrap.userPath = path;
			ensure(path);
			ensure(path + "/config");
			ensure(path + "/snippets");
			ensure(path + "/session");
			ensure(path + "/cache");
			ensure(path + "/themes");
			ensure(path + "/plugins");
			ensure(path + "/api");
			ensure(path + "/api/v1");
			ensure(path + "/api/v2");
			ensure(path + "/api/live");
		} else {
			setExternType(Electron, null);
			setExternType(FileSystem, cast FileSystem.FileSystemBrowser);
			setExternType(IPC, null);
			setExternType(Shell, null);
			setExternType(Menu, cast MenuFallback);
			setExternType(MenuItem, cast MenuFallback.MenuItemFallback);
			setExternType(AppTools, null);
			setExternType(FontScanner, cast FontScannerFallback);
		}
	}
}
#end
