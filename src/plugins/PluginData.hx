package plugins;

/**
 * ...
 * @author YellowAfterlife
 */
typedef PluginData = {
	/**
	 * Called after all of plugin's files are loaded up.
	 */
	?init:(state:PluginState)->Void,
	
	/**
	 * Called to unload the plugin. This is the plugin's opportunity to de-register anything it has
	 * set up.
	 */
	?cleanup:()->Void,
}
