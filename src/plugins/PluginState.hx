package plugins;
import ui.preferences.PrefPlugins;
import js.html.LinkElement;
import js.html.ScriptElement;
import js.html.Console;
import js.lib.Error;
import plugins.PluginConfig;

/**
 * ...
 * @author YellowAfterlife
 */
class PluginState {

	/**
		The name of the directory that this plugin's `config.json` resides in.
	**/
	public final name:PluginDirName;

	/**
		The path to this plugin's directory.
	**/
	public final dir:String;

	/**
		The configuration file of this plugin.
	**/
	public var config:Null<PluginConfig> = null;

	/**
		Some kind of error that occurred while loading or initialising this plugin.
	**/
	public var error(default, set):Null<Error> = null;
	
	/**
		The registered data as provided by the plugin's script invoking `GMEdit.register(...)`.
	**/
	public var data:Null<PluginData> = null;

	/**
		Whether this plugin registered a `cleanup()` handler. Plugins that cannot clean up cannot be
		stopped at runtime and require a restart to take effect.

		Plugins which fail to initialise correctly are also assumed to be incapable of cleaning up.
	**/
	public var canCleanUp(get, never):Bool;

	/**
		Whether this plugin has been started (`init()` has been called.)
	**/
	public var initialised:Bool = false;
	
	public final styles:Array<LinkElement> = [];
	public final scripts:Array<ScriptElement> = [];
	
	public function new(name:String, dir:String) {
		this.name = name;
		this.dir = dir;
	}

	/**
		Re-sync state of the associated preferences items, if they exist.
	**/
	public inline function syncPrefs() {
		PrefPlugins.sync(this);
	}

	function get_canCleanUp():Bool {
		return data?.cleanup != null;
	}

	function set_error(value:Null<Error>):Null<Error> {
		
		if (value != null) {
			Console.error('Error in plugin $name: ', value);
		}

		return error = value;
	}
}

typedef PluginCallback = (error:Null<Error>)->Void;
