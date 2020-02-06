package plugins;
import ace.AceWrap;
import electron.FileSystem;
import electron.FileWrap;
import haxe.DynamicAccess;
import js.html.Element;
import js.lib.Error;
import js.html.ErrorEvent;
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
	public var ready:Bool = false;
	public var error:Error = null;
	public var listeners:Array<PluginCallback> = [];
	public var data:PluginData = null;
	
	/** Scripts and styles */
	public var elements:Array<Element> = [];
	
	//
	public function new(name:String) {
		this.name = name;
	}
	public function destroy() {
		if (data != null && data.cleanup != null) data.cleanup();
		for (el in elements) {
			var p = el.parentElement;
			if (p != null) p.removeChild(el);
		}
		PluginManager.pluginMap.remove(name);
		PluginManager.registerMap.remove(config.name);
	}
	public function finish(?error:Error):Void {
		ready = true;
		if (error == null && data == null) {
			error = new Error('Plugin did not call register()');
		}
		if (error != null) {
			Main.console.error('Plugin load failed for $name:', error);
		} else Main.console.log("Plugin loaded: " + name);
		if (PluginManager.pluginList.indexOf(name) < 0) {
			PluginManager.pluginList.push(name);
		}
		//
		this.error = error;
		for (fn in listeners) fn(error);
		listeners.resize(0);
		//
		if (error == null && data.init != null) data.init(this);
	}
}
typedef PluginCallback = (error:Null<Error>)->Void;
