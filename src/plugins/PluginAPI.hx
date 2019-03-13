package plugins;
import haxe.DynamicAccess;
import ui.Sidebar;
import ace.AceTools;

/**
 * Exposes a globally visible GMEdit object that you can use for some random bits
 * @author YellowAfterlife
 */
@:keep @:expose("GMEdit")
class PluginAPI {
	
	/**
	 * A Haxe-specific inheritance function.
	 * Takes a parent prototype and an anonymous object containing new fields/overrides,
	 * returns the resulting new prototype.
	 */
	public static dynamic function extend<T>(
		proto:Dynamic, fields:DynamicAccess<Dynamic>
	):Dynamic {
		throw "Hooked at runtime!";
	}
	
	/**
	 * Registers a plugin in GMEdit.
	 * This must be called by your plugin's script.
	 */
	public static function register(pluginName:String, data:PluginData) {
		var state = PluginManager.registerMap[pluginName];
		if (state == null) throw "There's no plugin named " + pluginName;
		state.data = data;
	}
	
	// The following just point to specific classes for convenience
	public static var sidebar:Class<Sidebar> = Sidebar;
	public static var aceTools:Class<AceTools> = AceTools;
	
	/*
	 * GMEdit object supports all methods from Ace EventEmitter (like on, off, etc.)
	 * but Haxe side only needs event emission externs really
	 */
	@:native("_emit") public static dynamic function emit<E:{}>(eventName:String, ?e:E):Dynamic {
		throw "Failed to hook EventEmitter for PluginAPI";
	}
	@:native("_signal") public static dynamic function signal<E>(eventName:String, e:E):Void {
		throw "Failed to hook EventEmitter for PluginAPI";
	}
}
