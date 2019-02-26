package plugins;
import haxe.DynamicAccess;

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
	 */
	public static function register(pluginName:String, data:PluginData) {
		var state = PluginManager.registerMap[pluginName];
		if (state == null) throw "There's no plugin named " + pluginName;
		state.data = data;
	}
}
