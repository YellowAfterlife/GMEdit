package plugins;

/**
 * ...
 * @author YellowAfterlife
 */
typedef PluginConfig = {
	
	/** One of the scripts then should do GMEdit.register(name, {...}) */
	name:String,
	
	/** Optional - shows in Preferences */
	?description:String,
	
	/** Relative paths to .js files (if any) */
	?scripts:Array<String>,
	
	/** relative paths to .css files(if any) */
	?stylesheets:Array<String>,
	
	/** Plugins that should be loaded before this one can be loaded */
	?dependencies:Array<String>,
};
