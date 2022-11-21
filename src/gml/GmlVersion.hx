package gml;
import electron.Dialog;
import gml.GmlVersionV23;
import haxe.io.Path;
import js.lib.Error;
import js.lib.RegExp;
import tools.Dictionary;
import tools.JsTools;
import tools.NativeObject;
import gml.GmlVersionConfig;
import electron.Electron;
import electron.FileSystem;
import electron.FileWrap;

/**
 * A version determines how the parser works (e.g. GMS1 '' vs GMS2 @''),
 * what API entries are loaded, how the project is indexed, and so on.
 * 
 * Custom dialects are also "versions"
 * @author YellowAfterlife
 */
@:keep class GmlVersion {
	public static var none:GmlVersion = (function() {
		var v = new GmlVersion("none", "api/none", false);
		v.load();
		return v;
	})();
	public static var v1:GmlVersion;
	public static var v2:GmlVersion;
	//
	public static var map:Dictionary<GmlVersion> = new Dictionary();
	public static var list:Array<GmlVersion> = [];
	//
	
	/** API name, for code */
	public var name:String;
	
	public var dir:String;
	
	/** Display name, for humans */
	public var label:String;
	
	public var isCustom:Bool;
	
	public var config:GmlVersionConfig;
	
	public var isReady:Bool = false;
	
	public function new(name:String, dir:String, isCustom:Bool) {
		this.name = name;
		this.dir = dir;
		this.isCustom = isCustom;
	}
	public function load(?callback:Error->GmlVersion->Void) {
		if (dir == "api/none") {
			config = GmlVersionConfigDefaults.get(true);
			if (callback != null) JsTools.setImmediate(callback, null, this);
		} else {
			#if gmedit.live
			var vc = name.charAt(name.length - 1);
			config = GmlVersionConfigDefaults.get(vc == "2");
			config.resetLineCounterOnDefine = false;
			config.hasTernaryOperator = true;
			config.hasDefineArgs = true;
			config.additionalKeywords = ["in"];
			config.docMode = "gms" + vc;
			if (callback != null) JsTools.setImmediate(callback, null, this);
			#else
			var path = dir + "/config.json";
			if (Electron.isAvailable()) {
				try {
					config = FileSystem.readJsonFileSync(path);
					if (callback != null) JsTools.setImmediate(callback, null, this);
				} catch (x:Dynamic) {
					config = GmlVersionConfigDefaults.get(true);
					switch (Dialog.showMessageBox({
						type: "error",
						message: [
							'Failed to load config.json for API `$name` from `$path`!',
							'Consider fixing or removing it.',
							Std.string(x),
						].join("\n"),
						buttons: [
							"Show in directory",
							"Rename to disable",
							"Do nothing",
						],
					})) {
						case 0: FileWrap.showItemInFolder(path);
						case 1: {
							try {
								FileSystem.renameSync(path, Path.withExtension(path, "json.disabled"));
							} catch (x:Dynamic) {
								Dialog.showError("Failed to rename!");
							}
						};
					}
					if (callback != null) JsTools.setImmediate(callback, cast x, this);
				}
			} else {
				config = GmlVersionConfigDefaults.get(name == "v2");
				FileSystem.readJsonFile(path, function(e, c) {
					if (e == null) {
						config = c;
						Console.log('Loaded config for $name');
					} else {
						Console.error('Failed to load config for $name:', e);
					}
					if (callback != null) callback(e, this);
				});
			}
			#end
		}
	}
	
	//
	public function hasTernaryOperator() return config.hasTernaryOperator;
	public function hasStringEscapeCharacters() return config.hasStringEscapeCharacters;
	public function hasLiteralStrings() return config.hasLiteralStrings;
	public function hasSingleQuoteStrings() return config.hasSingleQuotedStrings;
	public function hasTemplateStrings():Bool {
		return config.hasTemplateStrings || GmlAPI.forceTemplateStrings;
	}
	public function hasFunctionLiterals():Bool {
		return config.additionalKeywords != null && config.additionalKeywords.contains("function");
	}
	public function hasJSDoc() return config.hasJSDoc;
	public function hasScriptArgs() return config.hasDefineArgs;
	public function resetOnDefine() return config.resetLineCounterOnDefine;
	public function getName() return name;
	//
	public function hasColorLiterals():Bool {
		return config.hasColorLiterals;
	}
	//
	static function init_1() {
		// load versions and their dependencies:
		for (v in list) map[v.name] = v;
		function loadVer(v:GmlVersion) {
			v.isReady = true;
			var selfConf = v.config;
			var parentName = selfConf.parent;
			var parentConf:GmlVersionConfig;
			switch (parentName) {
				case null: parentConf = null;
				case "gml1": parentConf = GmlVersionConfigDefaults.get(false);
				case "gml2": parentConf = GmlVersionConfigDefaults.get(true);
				default: {
					var parentVer = map[parentName];
					if (parentVer != null) {
						if (!parentVer.isReady) loadVer(parentVer);
						parentConf = parentVer.config;
					} else {
						Main.console.error('Parent `$parentName` for `${v.name}` is missing');
						parentConf = null;
					}
				};
			}
			// apply defaults from parent config (if any):
			if (parentConf != null) NativeObject.forField(parentConf, function(k) {
				switch (k) {
					case "parent", "name": {};
					default: {
						if (!Reflect.hasField(selfConf, k)) {
							Reflect.setField(selfConf, k, Reflect.field(parentConf, k));
						}
					}
				}
			});
			//
			var rs = selfConf.projectRegex;
			if (rs != null) {
				try {
					selfConf.projectRegexCached = new RegExp(rs, "i");
				} catch (x:Dynamic) {
					Main.console.error('Regexp `$rs` from `${v.name}` is invalid:', x);
				}
			}
			//
			if (selfConf.additionalKeywords == null) selfConf.additionalKeywords = [];
			selfConf.additionalKeywordsMap = new Dictionary();
			for (kw in selfConf.additionalKeywords) selfConf.additionalKeywordsMap[kw] = true;
			//
			selfConf.projectModeId = switch (selfConf.projectMode) {
				case "gms1": GMS1;
				case "gms2": GMS2;
				case "gmk-splitter": GmkSplitter;
				default: Other;
			}
			//
			v.label = selfConf.name;
			if (v.label == null) v.label = v.name;
		}
		for (v in list) loadVer(v);
		#if gmedit.live
		v1 = map["gmlivejs-v1"];
		v2 = map["gmlivejs-v2"];
		#else
		v1 = map["v1"];
		v2 = map["v2"];
		#end
	}
	public static function init() {
		#if gmedit.live
		list.push(new GmlVersion("gmlivejs-v1", Main.relPath("api/gmlivejs-v1"), false));
		list.push(new GmlVersion("gmlivejs-v2", Main.relPath("api/gmlivejs-v2"), false));
		for (v in list) v.load();
		init_1();
		#else
		if (Electron.isAvailable()) {
			// Allow overriding built-in APIs via user directory:
			var found = new Dictionary();
			function procDir(dir:String, isCustom:Bool):Void {
				for (id in FileSystem.readdirSync(dir)) {
					if (found.exists(id)) continue;
					var full = dir + "/" + id;
					if (!FileSystem.existsSync(full + "/config.json")) continue;
					found[id] = true;
					var v:GmlVersion;
					if (id == "v23") {
						v = new GmlVersionV23(id, full, isCustom);
					} else v = new GmlVersion(id, full, isCustom);
					v.load();
					list.push(v);
				}
			}
			procDir(FileWrap.userPath + "/api", true);
			procDir(Main.relPath("api"), false);
			// but show built-in APIs in front:
			var l1 = [];
			for (isCustom in [false, true]) for (v in list) {
				if (v.isCustom == isCustom) l1.push(v);
			}
			list = l1;
			init_1();
		} else {
			var ids = ["v1", "v2", "v23"];
			var left = ids.length;
			for (id in ids) {
				var path = Main.relPath("api/" + id);
				var v:GmlVersion;
				if (id == "v23") {
					v = new GmlVersionV23(id, path, false);
				} else v = new GmlVersion(id, path, false);
				v.load(function(e, v) {
					if (--left == 0) init_1();
				});
				list.push(v);
			}
		}
		#end
	}
	public static function detect(gml:String):GmlVersion {
		return GmlVersionDetect.run(gml);
	}
}
