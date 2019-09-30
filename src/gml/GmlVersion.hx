package gml;
import js.lib.RegExp;
import tools.Dictionary;
import tools.NativeObject;
import gml.GmlVersionConfig;
import electron.Electron;
import electron.FileSystem;
import electron.FileWrap;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlVersion {
	public static var none:GmlVersion = new GmlVersion("none", "api/none", false);
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
		if (dir == "api/none") {
			config = GmlVersionConfigDefaults.get(true);
		} else {
			#if lwedit
			config = GmlVersionConfigDefaults.get(false);
			config.resetLineCounterOnDefine = false;
			config.hasTernaryOperator = true;
			config.hasDefineArgs = true;
			config.additionalKeywords = ["in"];
			#else
			if (Electron.isAvailable()) {
				config = FileSystem.readJsonFileSync(dir + "/config.json");
			} else {
				config = GmlVersionConfigDefaults.get(name == "v2");
			}
			#end
		}
	}
	
	//
	public function hasTernaryOperator() return config.hasTernaryOperator;
	public function hasStringEscapeCharacters() return config.hasStringEscapeCharacters;
	public function hasLiteralStrings() return config.hasLiteralStrings;
	public function hasSingleQuoteStrings() return config.hasSingleQuotedStrings;
	public function hasTemplateStrings() return config.hasTemplateStrings;
	public function hasJSDoc() return config.hasJSDoc;
	public function hasScriptArgs() return config.hasDefineArgs;
	public function resetOnDefine() return config.resetLineCounterOnDefine;
	public function getName() return name;
	//
	public static function init() {
		#if lwedit
		list.push(new GmlVersion("gmlivejs-v1", Main.relPath("api/gmlivejs-v1"), false));
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
					list.push(new GmlVersion(id, full, isCustom));
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
		} else {
			list.push(new GmlVersion("v1", Main.relPath("api/v1"), false));
			list.push(new GmlVersion("v2", Main.relPath("api/v2"), false));
		}
		#end
		
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
			selfConf.projectModeId = switch (selfConf.projectMode) {
				case "gms1": 1;
				case "gms2": 2;
				default: 0;
			}
			//
			v.label = selfConf.name;
			if (v.label == null) v.label = v.name;
		}
		for (v in list) loadVer(v);
		v1 = map["v1"];
		v2 = map["v2"];
	}
	public static function detect(gml:String):GmlVersion {
		return GmlVersionDetect.run(gml);
	}
}
