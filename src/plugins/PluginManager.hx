package plugins;
import js.html.ScriptElement;
import tools.Result;
import js.lib.Promise;
import ui.Preferences;
import ace.AceWrap;
import electron.FileSystem;
import electron.FileWrap;
import js.html.Console;
import js.lib.Error;
import js.html.ErrorEvent;
import plugins.PluginAPI;
import plugins.PluginConfig;
import plugins.PluginState;
import tools.Dictionary;
using plugins.PluginManager.ConfigLoadErrorMethods;
using tools.ArrayTools;

/**
 * ...
 * @author YellowAfterlife
 */
class PluginManager {

	/** name from `config.json` -> state */
	public static var registry:Map<PluginRegName, PluginState> = new Map();

	/**
		Initialise the plugins API. Until this method has been executed, `PluginAPI` cannot be used,
		and plugins should not be initialised as they will not be able to access events.
	**/
	public static function initApi() {

		try {
			js.Syntax.code("window.$hxClasses = $hxClasses");
			js.Syntax.code("window.$gmedit = $hxClasses");
		} catch (x:Dynamic) {
			Console.error("Couldn't expose hxClasses:", x);
		}

		try {
			PluginAPI.extend = js.Syntax.code("$extend");
		} catch (x:Dynamic) {
			// this will not work for ES6 classes
			/*PluginAPI.extend = function(from:Dynamic, fields:Dynamic) {
				var proto = js.Object.create(from);
				js.Syntax.code("for (var fd in {1}) {0}[fd] = {1}[fd];", proto, fields);
				if (js.Syntax.strictEq(fields.toString, js.Object.prototype.toString)) {
					proto.toString = fields.toString;
				}
				return proto;
			}*/
			Console.error("Couldn't expose $extend:", x);
		}

		try {
			var EventEmitter = AceWrap.require("ace/lib/event_emitter").EventEmitter;
			ace.extern.AceOOP.implement(PluginAPI, EventEmitter);
		} catch (x:Dynamic) {
			Console.error("Couldn't add event emitting:", x);
		}

	}
	
	/**
		Find and load the installed plugins.
	**/
	public static function loadInstalledPlugins(): Promise<Void> {

		final pluginPaths = new Map<String, Array<PluginDirName>>();

		if (FileSystem.canSync) {
			
			final dirPaths = [FileWrap.userPath + "/plugins", Main.relPath("plugins")]
				.filter(FileSystem.existsSync);

			for (dirPath in dirPaths) {
				pluginPaths[dirPath] = FileSystem.readdirSync(dirPath);
			}

		} else {

			// Bundled web-version plugins.
			pluginPaths["plugins"] = [
				"outline-view",
				#if !lwedit
				"image-viewer",
				"ini-editor",
				#end
				"gen-enum-names",
				"show-aside",
			];

		}

		final skeletonPromises: Array<Promise<PluginState>> = [];

		for (dirPath => names in pluginPaths) {
			for (name in names) {

				final path = '$dirPath/$name';
				final plugin = new PluginState(name, path);

				skeletonPromises.push(loadConfig(path, name).then(function(result) {
					
					switch (result) {
						case Ok(data): plugin.config = data;
						case Err(err): plugin.error = err.toJsError();
					}

					return plugin;

				}));

			}
		}
		
		return Promise.all(skeletonPromises)
			.then(function(plugins) {
				final validPlugins = plugins.filter(function(plugin) return plugin.error == null);
				return Promise.all(validPlugins.map(load));
			})
			.then(function(plugins) {});
		
	}
	
	/**
		Start the loaded and enabled plugins.
	**/
	public static function startPlugins() {
		for (name => plugin in registry) {

			if (!isEnabled(name)) {
				continue;
			}

			start(plugin, false);

		}
	}

	/**
		Load the configuration file (`config.json`) of the given plugin.

		Returns a promise that resolves when the configuration has loaded, and contains a skeleton
		un-initialised plugin instance.

		If the `config.json` file fails to load - for instance, if it does not exist, or it has an
		invalid schema (is missing required props, e.g. registry name), the returned plugin will
		**NOT** be valid, and instead will have a populated `error` property.

		@param path Path to the plugin's content directory.
		@param name The directory name of the plugin to be loaded.
	**/
	static function loadConfig(
		path:String,
		name:PluginDirName
	): Promise<Result<PluginConfig, ConfigLoadError>> return new Promise(function(res, _) {

		final configPath = '$path/config.json';

		FileSystem.readJsonFile(configPath, function(
			error:Null<Error>,
			config:PluginConfig
		) {

			if (error != null) {
				return res(Err(ConfigLoadError.NoSuchFile(name, configPath)));
			}
			
			if (config.name == null) {
				return res(Err(ConfigLoadError.InvalidSchema(name, "Config does not specify plugin's registry name")));
			}
			
			if (config.scripts == null) {
				return res(Err(ConfigLoadError.InvalidSchema(name, "Config does not specify any scripts, plugin cannot register if it has no content")));
			}

			return res(Ok(config));

		});
		
	});
	
	/**
		Load the contents of a plugin - its scripts and stylesheets. Returns a promise that resolves
		when the plugin has either loaded successfully, or when an error is encountered whilst
		loading.

		A plugin has successfully loaded once:
		1. All of its scripts have finished loading.
		2. It calls `GMEdit.register(...)` for the name specified in its config.

		If all scripts have executed, but the plugin has *not* been registered, the plugin is
		considered to have failed to load.

		If any of the scripts included in the plugin fail to execute, the plugin is also considered
		to have failed to load.

		@param plugin The uninitialised plugin to be loaded.
	**/
	static function load(plugin:PluginState): Promise<Null<Error>> {

		registry[plugin.config.name] ??= plugin;

		// We can just let styles load up asynchronously.
		if (plugin.config.stylesheets != null) {
			for (styleName in plugin.config.stylesheets) {

				final link = Main.document.createLinkElement();
				link.setAttribute("data-plugin", plugin.config.name);
				link.rel = "stylesheet";
				link.href = '${plugin.dir}/$styleName';

				plugin.styles.push(link);

			}
		}

		// Some plugins might rely on script load order to be correctly assembled on the other side.
		// Due to this, we need to load scripts one-by-one, in the order they were stated in the
		// config file.
		final scriptsToLoad = Main.window.structuredClone(plugin.config.scripts);
		var nextScriptName = scriptsToLoad.shift();

		function loadNextScript(): Promise<Null<Error>> {
			return loadScript('${plugin.dir}/$nextScriptName').then(function(result) {

				final script = switch (result) {
					case Ok(data): data;
					case Err(err): return err.error;
				}

				script.setAttribute("data-plugin", plugin.config.name);
				plugin.scripts.push(script);

				if (scriptsToLoad.length == 0) {
					return null;
				}

				nextScriptName = scriptsToLoad.shift();
				return loadNextScript();

			});
		}

		final scriptsLoaded = loadNextScript();
		return scriptsLoaded.then(function(error:Null<Error>) {

			if (error != null) {
				plugin.error = error;
			}
			
			if (plugin.data == null) {
				plugin.error = new Error("Plugin finished loading but did not call `GMEdit.register(...)`");
			}

			if (plugin.error != null) {
				return plugin.error;
			}

			Console.log('Plugin loaded: ${plugin.name}');
			return null;

		});

	}

	/**
		Load the script at the provided path. Returns a promise that resolves when either the script
		has successfully loaded and executed, or returns an error if it fails.

		Scripts are executed immediately upon loading, so the `onload` event fires once the script
		body has been executed.
	**/
	static function loadScript(path:String): Promise<Result<ScriptElement, ErrorEvent>> {
		return new Promise(function(res, _) {

			final script = Main.document.createScriptElement();
			script.onload = function() return res(Ok(script));
			script.onerror = function(e) return res(Err(e));
			script.src = path;

			Main.document.head.appendChild(script);

		});
	}

	/**
		Reload the given plugin. If the plugin is enabled, it will be initialised immediately.
		Reloading also triggers a reload of any dependent plugins.
	**/
	public static function reload(plugin:PluginState): Promise<Void> {

		stop(plugin);

		for (script in plugin.scripts) {
			script.remove();
		}

		for (style in plugin.styles) {
			style.remove();
		}

		plugin.scripts.resize(0);
		plugin.styles.resize(0);
		plugin.error = null;
		plugin.data = null;

		return loadConfig(plugin.dir, plugin.name)
			.then(function(result) {

				final config = switch (result) {
					case Ok(data): data;
					case Err(err): return Promise.resolve(err.toJsError());
				}

				return load(plugin);

			})
			.then(function(error:Null<Error>) {

				if (error != null) {
					plugin.error = error;
					return Promise.resolve();
				}
			
				start(plugin, true);

				final dependentPromises = getDependents(plugin.config.name).map(reload);
				return Promise.all(dependentPromises).then(function(_) {});

			});

	}

	/**
		Start the given registered plugin. If this plugin is dependent on any other plugins, they
		will be started first.

		@param enableDeps Whether dependencies should be implicitly enabled in starting this plugin.
						  if `false`, if this plugin has dependencies that have been disabled by the
						  user, we will bail on starting this plugin.
	**/
	public static function start(plugin:PluginState, enableDeps:Bool): Null<Error> {

		if (plugin.initialised) {
			plugin.syncPrefs();
			return null;
		}

		if (plugin.error != null) {
			plugin.syncPrefs();
			return plugin.error;
		}

		for (regName in plugin.config.dependencies ?? []) {

			final dep = registry[regName];

			if (dep == null) {
				plugin.error = new Error('Cannot satisfy dependency $regName: plugin not found');
				plugin.syncPrefs();

				return plugin.error;
			}

			if (isEnabled(dep.config.name)) {
				
				if (dep.initialised) {
					continue;
				}

				final error = start(dep, enableDeps) ?? continue;
				plugin.error = new Error('Cannot satisfy dependency $regName as it failed to start: $error');
				plugin.syncPrefs();

				return plugin.error;

			}

			if (!enableDeps) {
				plugin.error = new Error('Cannot satisfy dependency on $regName: disabled by the user.');
				plugin.syncPrefs();

				return plugin.error;
			}

			Console.info('Enabling dependency: $regName');
			enable(dep.config.name);

		}

		for (link in plugin.styles) {
			Main.document.head.appendChild(link);
		}

		if (plugin.data.init != null) {
			try {
				plugin.data.init(plugin);
			} catch (err:Error) {

				plugin.error = err;
				plugin.syncPrefs();

				return err;

			}
		}

		plugin.error = null;
		plugin.initialised = true;
		plugin.syncPrefs();

		Console.info('Plugin started: ${plugin.config.name}');
		return null;
	}

	/**
		Stop the given registered plugin, calling its clean-up and removing its content from the
		DOM.
	**/
	public static function stop(plugin:PluginState) {

		if (!plugin.initialised) {
			plugin.syncPrefs();
			return;
		}

		if (!plugin.canCleanUp) {
			plugin.syncPrefs();
			return;
		}

		try {
			plugin.data.cleanup();
		} catch (err:Error) {
			plugin.error = err;
		}

		for (link in plugin.styles) {
			link.remove();
		}

		plugin.initialised = false;
		plugin.syncPrefs();

		Console.info('Plugin stopped: ${plugin.config.name}');
		
	}

	/**
		Get the list of plugins which are dependent on the given plugin.
	**/
	static function getDependents(name:PluginRegName): Array<PluginState> {

		final dependents: Array<PluginState> = [];

		for (depName => _ in registry) {
			
			if (depName == name) {
				continue;
			}

			final maybeDependent = registry[depName] ?? continue;
			final dependencies = maybeDependent.config.dependencies ?? continue;

			if (dependencies.contains(name)) {
				dependents.push(maybeDependent);
			}

		}

		return dependents;

	}

	/**
		Returns whether the given plugin is enabled, as the user may disable plugins.
	**/
	public static function isEnabled(name:PluginRegName): Bool {
		return !Preferences.current.disabledPlugins.contains(name);
	}

	/**
		Enable the given plugin.
	**/
	public static function enable(name:PluginRegName): Null<Error> {

		if (!isEnabled(name)) {
			Preferences.current.disabledPlugins.remove(name);
			Preferences.save();
		}

		final plugin = registry[name] ?? return new Error('Cannot start non-existent plugin $name');
		return start(plugin, true);

	}

	/**
		Disable the given plugin.
	**/
	public static function disable(name:PluginRegName) {

		if (isEnabled(name)) {
			Preferences.current.disabledPlugins.push(name);
			Preferences.save();
		}

		for (dependent in getDependents(name)) {
			Console.info('Disabling dependent plugin: ${dependent.name}');
			disable(dependent.config.name);
		}

		final plugin = registry[name];

		if (plugin != null) {
			stop(plugin);
		}

	}

}

/**
	An error encountered whilst attempting to load a plugin's configuration file.
**/
private enum ConfigLoadError {
	NoSuchFile(pluginName:PluginDirName, path:String);
	InvalidSchema(pluginName:PluginDirName, info:String);
}

private class ConfigLoadErrorMethods {
	public static inline function toJsError(error:ConfigLoadError): Error return switch (error) {
		case NoSuchFile(pluginName, path): new Error('$pluginName\'s config.json ("$path") does not exist');
		case InvalidSchema(pluginName, info): new Error('$pluginName\'s config.json is invalid: $info');
	};
}
