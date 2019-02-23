package plugins;
import electron.FileSystem;
import electron.FileWrap;
import js.Error;
import js.html.ErrorEvent;
import plugins.PluginAPI;

/**
 * ...
 * @author YellowAfterlife
 */
class PluginManager {
	/// name -> state
	public static var pluginMap:Map<String, PluginState> = new Map();
	/// name -> containing directory
	private static var pluginDir:Map<String, String> = new Map();
	/// name from config.json -> state
	public static var registerMap:Map<String, PluginState> = new Map();
	
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
		var state = new PluginState(name);
		if (cb != null) state.listeners.push(cb);
		FileSystem.readJsonFile('$dir/$name/config.json', function(err, conf:PluginConfig) {
			if (err != null) {
				state.finish(err);
				return;
			}
			if (conf.name == null) {
				state.finish(new Error("Plugin's config.json has no name"));
				return;
			} else registerMap.set(conf.name, state);
			if (conf.scripts == null) {
				state.finish(new Error("Plugin's config.json has no scripts"));
				return;
			}
			//
			function loadScripts():Void {
				var queue = conf.scripts.slice(0);
				function loadNextScript():Void {
					var rel = queue.shift();
					var script = Main.document.createScriptElement();
					script.setAttribute("plugin", conf.name);
					script.onload = function(_) {
						if (queue.length > 0) {
							loadNextScript();
						} else state.finish();
					};
					script.onerror = function(e:ErrorEvent) {
						state.finish(e.error);
					};
					script.src = '$dir/$name/$rel';
					Main.document.head.appendChild(script);
				}
				if (queue.length > 0) {
					loadNextScript();
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
						if (--depc <= 0) loadScripts();
					}
				});
			} else loadScripts();
		});
	}
	
	public static function init() {
		try {
			Type.resolveClass("Main");
			untyped __js__("window.$hxClasses = $hxClasses");
			untyped __js__("window.$gmedit = $hxClasses");
		} catch (x:Dynamic) {
			Main.console.error("Couldn't expose hxClasses:", x);
		}
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
		} else list = [ // base package
			"plugins/enum-names"
		];
		//
		for (name in list) load(name);
	}
}
typedef PluginCallback = (error:Null<Error>)->Void;
class PluginState {
	public var name:String;
	public var ready:Bool = false;
	public var error:Error = null;
	public var listeners:Array<PluginCallback> = [];
	public var data:PluginData = null;
	public function new(name:String) {
		this.name = name;
	}
	public function finish(?error:Error):Void {
		ready = true;
		if (error == null && data == null) {
			error = new Error('Plugin did not call register()');
		}
		if (error != null) {
			Main.console.error('Plugin load failed for $name:', error);
		} else Main.console.log("Plugin loaded: " + name);
		this.error = error;
		for (fn in listeners) fn(error);
		listeners.resize(0);
		if (error == null && data.init != null) data.init();
	}
}
