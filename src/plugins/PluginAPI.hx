package plugins;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep @:expose("GMEdit")
class PluginAPI {
	@:doc public static function register(pluginName:String, data:PluginData) {
		var state = PluginManager.registerMap[pluginName];
		if (state == null) throw "There's no plugin named " + pluginName;
		state.data = data;
	}
}
