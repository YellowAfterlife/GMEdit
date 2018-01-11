package electron;
import gmx.SfGmx;
import js.Error;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_API") extern class Electron {
	public static var shell:Dynamic;
	public static var remote:Dynamic;
	public static var ipcRenderer:Dynamic;
	public static inline function init():Void {
		inline function load(hxname:String, ename:String):Void {
			untyped window[hxname] = require(ename);
		}
		inline function set(hxname:String, ref:Dynamic):Void {
			if (ref == null) throw "Can't find " + hxname;
			untyped window[hxname] = ref;
		}
		load("Electron_API", "electron");
		load("Electron_FS", "fs");
		set("Electron_Dialog", remote.dialog);
		set("Electron_IPC", ipcRenderer);
		set("Electron_Shell", shell);
		set("Electron_Menu", remote.Menu);
		set("Electron_MenuItem", remote.MenuItem);
	}
}
