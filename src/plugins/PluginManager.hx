package plugins;
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

/**
 * ...
 * @author YellowAfterlife
 */
class PluginManager {

	/** name from `config.json` */
	public static var pluginList:Array<String> = [];
	/** name -> state */
	public static var pluginMap:Dictionary<PluginState> = new Dictionary();
	/** name -> containing directory */
	public static var pluginDir:Dictionary<String> = new Dictionary();
	/** name from `config.json` -> state */
	public static var registerMap:Dictionary<PluginState> = new Dictionary();
	
	public static function load(name:String, ?cb:PluginCallback) {
		var state = pluginMap[name];
		if (state != null) {
			if (state.ready) {
				cb(state.error);
			} else {
				state.listeners.push(cb);
			}
			return;
		}
		//
		var dir = pluginDir[name];
		if (dir == null) {
			if (cb != null) cb(new Error('Plugin $name does not exist'));
			return;
		}
		//
		var state = new PluginState(name, dir + "/" + name);
		if (cb != null) state.listeners.push(cb);
		pluginMap.set(name, state);
		FileSystem.readJsonFile('$dir/$name/config.json', function(err, conf:PluginConfig) {
			if (err != null) {
				state.finish(err);
				return;
			}
			if (conf.name == null) {
				state.finish(new Error("Plugin's config.json has no name"));
				return;
			} else {
				state.config = conf;
				registerMap.set(conf.name, state);
			}
			//
			function loadResources():Void {
				var queue:Array<{kind:Int,rel:String}> = [];
				if (conf.stylesheets != null) for (rel in conf.stylesheets) {
					queue.push({kind:1, rel:rel});
				}
				if (conf.scripts != null) for (rel in conf.scripts) {
					queue.push({kind:0, rel:rel});
				}
				var suffix = "";// "?t=" + Date.now().getTime();
				function loadNextResource():Void {
					var pair = queue.shift();
					var rel = pair.rel;
					switch (pair.kind) {
						case 0: {
							var script = Main.document.createScriptElement();
							script.setAttribute("plugin", conf.name);
							script.onload = function(_) {
								if (queue.length > 0) {
									loadNextResource();
								} else state.finish();
							};
							script.onerror = function(e:ErrorEvent) {
								state.finish(e.error);
							};
							script.src = '$dir/$name/$rel' + suffix;
							state.scripts.push(script);
							Main.document.head.appendChild(script);
						};
						case 1: {
							var style = Main.document.createLinkElement();
							style.setAttribute("plugin", conf.name);
							style.onload = function(_) {
								if (queue.length > 0) {
									loadNextResource();
								} else state.finish();
							};
							style.onerror = function(e:ErrorEvent) {
								state.finish(e.error);
							}
							style.rel = "stylesheet";
							style.href = '$dir/$name/$rel' + suffix;
							state.styles.push(style);
							Main.document.head.appendChild(style);
						};
					}
				}
				if (queue.length > 0) {
					loadNextResource();
				} else state.finish();
			}
			//
			var deps = conf.dependencies;
			if (deps != null && deps.length > 0) {
				var depc = deps.length;
				for (dep in deps) load(dep, function(e:Error) {
					if (e != null) {
						state.finish(e);
					} else if (!state.ready) {
						if (--depc <= 0) loadResources();
					}
				});
			} else loadResources();
		});
	}

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
		Load and initialise the list of installed plugins.
		Executes `onLoaded` on completion.
	**/
	public static function loadInstalledPlugins(onLoaded:Void->Void) {
		
		//
		var list:Array<String>;
		if (FileSystem.canSync) {
			list = [];
			for (dir in [
				FileWrap.userPath + "/plugins",
				Main.relPath("plugins"),
			]) if (FileSystem.existsSync(dir)
			) for (name in FileSystem.readdirSync(dir)) {
				var full = '$dir/$name/config.json';
				if (FileSystem.existsSync(full) && list.indexOf(name) < 0) {
					list.push(name);
					pluginDir.set(name, dir);
				}
			}
		} else { // base package for web version
			list = [
				"outline-view",
				#if !lwedit
				"image-viewer",
				"ini-editor",
				#end
				"gen-enum-names",
				"show-aside",
			];
			for (name in list) {
				pluginDir[name] = "plugins";
			}
		}
		//
		var pluginsLeft = 1;

		function next(_) {
			if (--pluginsLeft <= 0) {
				startEnabledPlugins();
				onLoaded();
			}
		}

		for (name in list) {
			pluginsLeft += 1;
			load(name, next);
		}

		next(null);
	}
	
	/**
		Start the loaded and enabled plugins.
	**/
	static function startEnabledPlugins() {
		for (pluginName in pluginList) {

			if (!isEnabled(pluginName)) {
				continue;
			}

			start(pluginName, false);

		}
	}

	/**
		Reload the given plugin. If the plugin is enabled, it will be initialised immediately.
		Reloading also triggers a reload of any dependent plugins.

		@param onFinished Optional callback to execute with the reloaded plugin state.
	**/
	public static function reload(pluginName:String, onFinished:Null<PluginState -> Void> = null) {

		stop(pluginName);

		final pluginState = pluginMap[pluginName];

		for (script in pluginState.scripts) {
			script.remove();
		}

		for (style in pluginState.styles) {
			style.remove();
		}

		final registeredName = pluginState.config?.name;

		if (registeredName != null) {
			registerMap.remove(registeredName);
		}
		
		pluginMap.remove(pluginName);

		load(pluginName, function(_) {
			
			start(pluginName, true);

			for (dependent in getDependents(pluginName)) {
				Console.info('Reloading dependent: ${dependent.name}');
				reload(dependent.name);
			}

			if (onFinished != null) {
				onFinished(pluginMap[pluginName]);
			}
			
		});

	}

	/**
		Start the given registered plugin. If this plugin is dependent on any other plugins, they
		will be started first.

		@param enableDeps Whether dependencies should be implicitly enabled in starting this plugin.
						  if `false`, if this plugin has dependencies that have been disabled by the
						  user, we will bail on starting this plugin.
	**/
	public static function start(pluginName:String, enableDeps:Bool): Null<Error> {

		final pluginState = pluginMap[pluginName] ?? return null;

		if (pluginState.initialised) {
			pluginState.syncPrefs();
			return null;
		}

		if (pluginState.error != null) {
			pluginState.syncPrefs();
			return pluginState.error;
		}

		if (pluginState.config.dependencies != null) {
			for (regName in pluginState.config.dependencies) {

				final dep = registerMap[regName];

				if (dep == null) {
					pluginState.error = new Error('Cannot satisfy dependency $regName: plugin not found');
					pluginState.syncPrefs();
					return pluginState.error;
				}

				if (dep.initialised) {
					continue;
				}

				if (isEnabled(dep.name)) {

					final error = start(dep.name, enableDeps);

					if (error != null) {
						pluginState.error = new Error('Cannot satisfy dependency $regName: $error');
						pluginState.syncPrefs();
						return pluginState.error;
					}

					continue;

				}

				if (!enableDeps) {
					pluginState.error = new Error('Cannot satisfy dependency on $regName: disabled by the user.');
					pluginState.syncPrefs();

					return pluginState.error;
				}

				Console.info('Enabling dependency: $regName');
				enable(dep.name);

			}
		}

		for (style in pluginState.styles) {
			style.disabled = false;
		}

		if (pluginState.data.init != null) {
			try {
				pluginState.data.init(pluginState);
			} catch (err:Error) {

				pluginState.error = err;
				pluginState.syncPrefs();

				return err;

			}
		}

		pluginState.error = null;
		pluginState.initialised = true;
		pluginState.syncPrefs();

		Console.info('Plugin started: $pluginName');
		return null;
	}

	/**
		Stop the given registered plugin, calling its clean-up and removing its content from the
		DOM.
	**/
	public static function stop(pluginName:String) {

		final pluginState = pluginMap[pluginName] ?? return;

		if (!pluginState.initialised) {
			pluginState.syncPrefs();
			return;
		}

		if (!pluginState.canCleanUp) {
			pluginState.syncPrefs();
			return;
		}

		try {
			pluginState.data.cleanup();
		} catch (err:Error) {
			pluginState.error = err;
		}

		for (style in pluginState.styles) {
			style.disabled = true;
		}

		pluginState.initialised = false;
		pluginState.syncPrefs();

		Console.info('Plugin stopped: $pluginName');
		
	}

	/**
		Get the list of plugins which are dependent on the given plugin.
	**/
	static function getDependents(pluginName:String): Array<PluginState> {

		final pluginState = pluginMap[pluginName];
		final pluginRegName = pluginState.config.name;
		final dependents: Array<PluginState> = [];

		for (regName in pluginList) {
			
			if (regName == pluginRegName) {
				continue;
			}

			final maybeDependent = registerMap[regName] ?? continue;
			final dependencies = maybeDependent.config.dependencies ?? continue;

			if (dependencies.contains(pluginRegName)) {
				dependents.push(maybeDependent);
			}

		}

		return dependents;

	}

	/**
		Returns whether the given plugin is enabled, as the user may disable plugins.
	**/
	public static function isEnabled(pluginName:String): Bool {
		return !Preferences.current.disabledPlugins.contains(pluginName);
	}

	/**
		Enable the given plugin.
	**/
	public static function enable(pluginName:String) {

		if (!isEnabled(pluginName)) {
			Preferences.current.disabledPlugins.remove(pluginName);
			Preferences.save();
		}

		start(pluginName, true);

	}

	/**
		Disable the given plugin.
	**/
	public static function disable(pluginName:String) {

		if (isEnabled(pluginName)) {
			Preferences.current.disabledPlugins.push(pluginName);
			Preferences.save();
		}

		for (dependent in getDependents(pluginName)) {
			Console.info('Disabling dependent plugin: ${dependent.name}');
			disable(dependent.name);
		}

		stop(pluginName);

	}

}
