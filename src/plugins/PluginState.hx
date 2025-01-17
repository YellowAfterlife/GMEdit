package plugins;
import ace.AceWrap;
import electron.FileSystem;
import electron.FileWrap;
import haxe.DynamicAccess;
import js.html.Element;
import js.lib.Error;
import js.html.ErrorEvent;
import js.html.Console;
import plugins.PluginAPI;
import plugins.PluginConfig;
import plugins.PluginState;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class PluginState {
	public var name:String;
	public var config:PluginConfig;
	public var dir:String;
	public var ready:Bool = false;
	public var error:Error = null;
	public var listeners:Array<PluginCallback> = [];
	public var data:PluginData = null;
	
	/** Scripts and styles */
	public var elements:Array<Element> = [];
	
	//
	public function new(name:String, dir:String) {
		this.name = name;
		this.dir = dir;
	}

	public function finish(?error:Error):Void {
		ready = true;
		if (error == null && data == null) {
			error = new Error('Plugin did not call register()');
		}
		if (error != null) {
			Console.error('Plugin load failed for $name:', error);
		} else Console.log("Plugin loaded: " + name);
		if (PluginManager.pluginList.indexOf(name) < 0) {
			PluginManager.pluginList.push(name);
		}
		//
		this.error = error;
		for (fn in listeners) fn(error);
		listeners.resize(0);
		// moved to PluginManager.dispatchInitCallbacks
		/*if (error == null && data.init != null) {
			var t = Date.now().getTime();
			data.init(this);
			var dt = Date.now().getTime() - t;
			if (dt > 500) Console.warn('init() for $name took ${dt}ms.');
		}*/
	}
}
typedef PluginCallback = (error:Null<Error>)->Void;
