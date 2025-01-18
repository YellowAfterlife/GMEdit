package plugins;

/**
	The configuration data from `config.json` of a plugin. Holds the registry name of the plugin,
	which should always be preferred over the dir name if available, along with the list of resource
	names and dependencies of the plugin.

	@author YellowAfterLife
**/
typedef PluginConfig = {
	
	/** One of the scripts then should do GMEdit.register(name, {...}) */
	name:PluginRegName,
	
	/** Optional - shows in Preferences */
	?description:String,
	
	/** Relative paths to .js files */
	scripts:Array<String>,
	
	/** relative paths to .css files(if any) */
	?stylesheets:Array<String>,
	
	/** 
		Plugins that should be initialised before this plugin.
	**/
	?dependencies:Array<PluginRegName>,
};

/**
	Name of a given plugin in the plugin registry. This name is derived from a plugin's
	`config.json`, and is the name used for `GMEdit.register(...)`.
**/
abstract PluginRegName(String) to String {}

/**
	Name of a given plugin's directory. We cannot know what a plugin's registry name
	is until the plugin's config has been loaded, so this is another unique identifier which is used
	to then derive the registry name.
**/
abstract PluginDirName(String) from String to String {}
