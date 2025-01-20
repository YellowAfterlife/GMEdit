package plugins;

import gml.Project;
import js.html.Element;

/**
 * Registration data for a given plugin, provided by calling `GMEdit.register(name, {...})`.
 * Should ideally implement `init` and `cleanup` at least.
 * 
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

	/**
		Called to build out the preferences list for this plugin in its respective group in the
		preferences menu.

		Implementing this method is preferable over `PluginEvents.preferencesBuilt`, which fires
		only when the entire preferences menu is being constructed, and plugins are forced to
		locate their respective elements manually, and does not give plugins an opportunity to
		build their preferences list when the plugin is reloaded in-place.
	**/
	?buildPreferences:(element:Element)->Void,

	/**
		Called to build out the project properties for this plugin, in its respective group, just
		like the above `buildPreferences`.

		This method is, equally, preferable over `PluginEvents.projectPropertiesBuilt`, for the same
		reasons.

		Unlike the mentioned event, this method matches the preferences menu by providing a group
		for the plugin implicitly, if the plugin implements this method.

		@param element The body of the group element belonging to this plugin.
		@param project The project for which this properties menu is for.
	**/
	?buildProjectProperties:(element:Element, project:Project)->Void,
}
