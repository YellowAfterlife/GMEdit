package plugins;

/**
 * ...
 * @author YellowAfterlife
 */
typedef PluginConfig = {
	
	/// one of the scripts then should do GMEdit.register(name, {...})
	name:String,
	
	/// relative paths to .js files
	scripts:Array<String>,
	
	/// plugins that should be loaded before this one can be loaded
	?dependencies:Array<String>,
};
