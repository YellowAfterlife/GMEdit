package plugins;
import ui.preferences.PrefPlugins.PluginPrefItem;
import js.html.LinkElement;
import js.html.StyleElement;
import js.html.ScriptElement;
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

	/**
		Whether this plugin registered a `cleanup()` handler. Plugins that cannot clean up cannot be
		stopped at runtime and require a restart to take effect.

		Plugins which fail to initialise correctly are also assumed to be incapable of cleaning up.
	**/
	public var canCleanUp(default, null):Bool = false;

	/**
		The preferences item associated with this plugin.
		TODO: this is some binding that I'm not a big fan of.
	**/
	public var prefItem(null, default):Null<PluginPrefItem>;

	/**
		Whether this plugin has been started (`init()` has been called.)
	**/
	public var initialised:Bool = false;
	
	public var styles:Array<LinkElement> = [];
	public var scripts:Array<ScriptElement> = [];
	
	public function new(name:String, dir:String) {
		this.name = name;
		this.dir = dir;
	}

	public function finish(?error:Error):Void {
		
		ready = true;

		if (data != null) {
			canCleanUp = (data.cleanup != null);
		} else if (error == null) {
			error = new Error("Plugin did not call register()");
		}

		if (error != null) {
			Console.error('Plugin load failed for $name:', error);
			canCleanUp = false;
		} else Console.log("Plugin loaded: " + name);
		if (PluginManager.pluginList.indexOf(name) < 0) {
			PluginManager.pluginList.push(name);
		}
		
		this.error = error;
		for (fn in listeners) fn(error);
		listeners.resize(0);
	}

	/**
		Re-sync state of the associated preferences item, if one exists.
	**/
	public inline function syncPrefs() {
		if (prefItem != null) {
			prefItem.sync();
		}
	}

}

typedef PluginCallback = (error:Null<Error>)->Void;
