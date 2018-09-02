package gml;
import electron.FileSystem;
import gml.GmlEnum;
import haxe.io.Path;
import js.RegExp;
import parsers.GmlParseAPI;
import tools.Dictionary;
import ace.AceWrap;
import tools.NativeString;
import ui.Preferences;
import ui.liveweb.LiveWeb;
using tools.ERegTools;
using StringTools;

/**
 * Stores current API state and projct-specific data.
 * @author YellowAfterlife
 */
@:expose("GmlAPI")
class GmlAPI {
	public static var version(default, set):GmlVersion = GmlVersion.none;
	private static inline function set_version(v:GmlVersion):GmlVersion {
		if (version != v) {
			version = v;
			init();
		}
		return v;
	}
	//
	public static var kwList:Array<String> = ["globalvar", "var",
		"if", "then", "else", "begin", "end", "for", "while", "do", "until", "repeat",
		"switch", "case", "default", "break", "continue", "with", "exit", "return",
		"self", "other", "noone", "all", "global", "local",
		"mod", "div", "not", "and", "or", "xor", "enum",
		#if lwedit
		"in", "debugger",
		#end
		"true", "false", // generally handled separately
	];
	/** whether something is a "flow" (branching, etc. - delimiting) keyword */
	public static var kwFlow:Dictionary<Bool> = Dictionary.fromKeys(
		("if|then|else|begin|end"
		+ "|for|while|do|until|repeat|with|break|continue"
		+ "|switch|case|default"
		+ "|exit|return|wait"
		+ "|enum|var|globalvar"
		).split("|"), true
	);
	//
	public static var scopeResetRx = new js.RegExp('^(?:#define|#event)[ \t]+([\\w:]+)', '');
	//
	public static var helpLookup:Dictionary<String> = null;
	public static var helpURL:String = null;
	public static var ukSpelling:Bool = false;
	//
	public static var stdDoc:Dictionary<GmlFuncDoc> = new Dictionary();
	public static var stdComp:AceAutoCompleteItems = [];
	public static var stdKind:Dictionary<String> = new Dictionary();
	public static function stdClear() {
		stdDoc = new Dictionary();
		stdComp.clear();
		var sk = new Dictionary();
		inline function add(s:String) {
			sk.set(s, "keyword");
		}
		for (s in kwList) add(s);
		if (version == GmlVersion.live) {
			add("wait");
			add("in");
			add("try");
			add("catch");
			add("throw");
		}
		if (Preferences.current.importMagic) add("new");
		stdKind = sk;
	}
	// extension scope
	public static var extDoc:Dictionary<GmlFuncDoc> = new Dictionary();
	public static var extKind:Dictionary<String> = new Dictionary();
	public static var extComp:AceAutoCompleteItems = [];
	public static var extCompMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	public static function extClear() {
		extDoc = new Dictionary();
		extKind = new Dictionary();
		extComp.clear();
		extCompMap = new Dictionary();
	}
	// script/object scope
	/** script name -> doc */
	public static var gmlDoc:Dictionary<GmlFuncDoc> = new Dictionary();
	
	/** word -> ACE kind */
	public static var gmlKind:Dictionary<String> = new Dictionary();
	
	/** array of auto-completion items */
	public static var gmlComp:AceAutoCompleteItems = [];
	
	/** enum name -> enum, for highlighting */
	public static var gmlEnums:Dictionary<GmlEnum> = new Dictionary();
	
	/** macro name -> macro */
	public static var gmlMacros:Dictionary<GmlMacro> = new Dictionary();
	
	/** asset type -> asset name -> id*/
	public static var gmlAssetIDs:Dictionary<Dictionary<Int>> = new Dictionary();
	
	/** asset name -> asset AC */
	public static var gmlAssetComp:Dictionary<AceAutoCompleteItem> = new Dictionary();
	
	/** global field name -> data */
	public static var gmlGlobalFieldMap:Dictionary<GmlGlobalField> = new Dictionary();
	
	/** global field AC items */
	public static var gmlGlobalFieldComp:AceAutoCompleteItems = [];
	
	/** instance variables */
	public static var gmlInstFieldMap:Dictionary<GmlGlobalField> = new Dictionary();
	
	/** instance variable auto-completion */
	public static var gmlInstFieldComp:AceAutoCompleteItems = [];
	
	/** Used for F12/middle-click */
	public static var gmlLookup:Dictionary<GmlLookup> = new Dictionary();
	
	/** `\n` separated asset names for regular expression search */
	public static var gmlLookupText:String = "";
	
	#if lwedit
	/** Function name -> argument count (-1 for any) */
	public static var lwArgc:Dictionary<Int> = new Dictionary();
	
	/** Whether something is a constant */
	public static var lwConst:Dictionary<Bool> = new Dictionary();
	
	/** (readOnly=1|array=2|inst=4) */
	public static var lwFlags:Dictionary<Int> = new Dictionary();
	
	/** Whether the "function" is instance-specific */
	public static var lwInst:Dictionary<Bool> = new Dictionary();
	#end
	
	public static function gmlClear() {
		gmlDoc = new Dictionary();
		gmlKind = new Dictionary();
		gmlComp.clear();
		gmlEnums = new Dictionary();
		gmlAssetIDs = new Dictionary();
		gmlAssetComp = new Dictionary();
		gmlGlobalFieldMap = new Dictionary();
		gmlGlobalFieldComp.clear();
		gmlInstFieldMap = new Dictionary();
		gmlInstFieldComp.clear();
		gmlLookup = new Dictionary();
		gmlLookupText = "";
		for (type in gmx.GmxLoader.assetTypes) {
			gmlAssetIDs.set(type, new Dictionary());
		}
	}
	//
	public static function init() {
		stdClear();
		GmlExternAPI.gmlResetOnDefine = version.resetOnDefine();
		if (version == GmlVersion.none) return;
		//
		var getContent_rx = new RegExp("\r\n", "g");
		function getContent(path:String, fn:String->Void):Void {
			if (FileSystem.canSync) {
				var rp = Main.relPath(path);
				if (FileSystem.existsSync(rp)) {
					var s = FileSystem.readFileSync(rp, "utf8");
					s = NativeString.replaceExt(s, getContent_rx, "\n");
					fn(s);
				} else fn(null);
			} else {
				FileSystem.readTextFile(path, function(e, s) {
					fn(e == null ? s : null);
				});
			}
		}
		var dir = "api/" + version.getName();
		//
		helpURL = null;
		helpLookup = null;
		ukSpelling = Preferences.current.ukSpelling;
		var confPath = Main.relPath(dir + "/config.json");
		var files:Array<String> = null;
		var assets:Array<String> = null;
		FileSystem.readJsonFile(confPath, function(error, conf:GmlConfig) {
			if (error == null) {
				files = conf.apiFiles;
				assets = conf.assetFiles;
				if (ukSpelling == null) ukSpelling = conf.ukSpelling;
				//
				var confKeywords = conf.keywords;
				if (confKeywords != null) for (kw in confKeywords) {
					stdKind.set(kw, "keyword");
				}
				//
				helpURL = conf.helpURL;
				var helpIndexPath = conf.helpIndex;
				if (helpIndexPath != null) {
					helpIndexPath = Main.relPath(dir + "/" + helpIndexPath);
					FileSystem.readTextFile(helpIndexPath, function(err, helpIndexJs) {
						if (err != null) return;
						helpLookup = new Dictionary();
						helpIndexJs = helpIndexJs.substring(helpIndexJs.indexOf("["));
						helpIndexJs = helpIndexJs.substring(0, helpIndexJs.indexOf(";"));
						try {
							var helpIndexArr:Array<Array<Dynamic>> = haxe.Json.parse(helpIndexJs);
							for (pair in helpIndexArr) {
								var item:Dynamic = pair[1];
								if (Std.is(item, Array)) item = item[0][1];
								helpLookup.set(pair[0], item);
							}
						} catch (x:Dynamic) {
							trace("Couldn't parse help index:", x);
						}
					});
				}
			}
			//
			if (assets != null) for (file in assets) {
				getContent('$dir/$file', function(raw) {
					GmlParseAPI.loadAssets(raw, { kind: stdKind, comp: stdComp });
				});
			}
			//
			var data = {
				kind: stdKind,
				doc: stdDoc,
				comp: stdComp,
				ukSpelling: ukSpelling,
				version: version,
				#if lwedit
				lwArgc: lwArgc,
				lwInst: lwInst,
				lwConst: lwConst,
				lwFlags: lwFlags,
				#end
			};
			if (files != null) for (file in files) {
				var path = dir + "/" + file;
				getContent(path, function(raw) {
					if (raw != null) {
						GmlParseAPI.loadStd(raw, data);
					} else Main.console.error("Couldn't load " + path);
				});
			} else {
				var raw:String = "";
				function fin_inst(s:String) {
					if (s != null) ~/^(\w+)$/gm.each(s, function(rx:EReg) {
						var name = rx.matched(1);
						raw = new EReg('^$name\\b', "gm").replace(raw, ":" + name);
					});
					GmlParseAPI.loadStd(raw, data);
					#if lwedit
					if (lwArgc != null) { // give GMLive a copy of data
						var cb = Reflect.field(Main.window, "lwSetAPI");
						if (cb != null) cb(data);
						LiveWeb.readyUp();
					}
					// so that the welcome page highlights correctly:
					Main.aceEditor.session.bgTokenizer.start(0);
					#end
				}
				function fin_exclude(s:String) {
					if (s != null) ~/^(\w+)(\*?)$/gm.each(s, function(rx:EReg) {
						var name = rx.matched(1);
						if (rx.matched(2) != "") {
							raw = new EReg('^$name.*$', "gm").replace(raw, "");
						} else {
							raw = new EReg('^$name\\b.*$', "gm").replace(raw, "");
						}
					});
					getContent(dir + "/inst.gml", fin_inst);
				}
				function fin_replace(s:String) {
					if (s != null) ~/^(\w+).+$/gm.each(s, function(rx:EReg) {
						var name = rx.matched(1);
						var code = rx.matched(0);
						raw = (new EReg('^$name.+$$', "gm")).map(raw, function(r1) {
							return code;
						});
					});
					getContent(dir + '/exclude.gml', fin_exclude);
				}
				function fin_extra(s:String) {
					if (s != null && s != "") raw += "\n" + s;
					#if lwedit
					raw += "\ntrace(...)";
					#end
					getContent(dir + "/replace.gml", fin_replace);
				}
				function fin_fnames(s:String) {
					if (s != null) {
						raw = s;
						getContent(dir + "/extra.gml", fin_extra);
					} else {
						Main.window.alert("Couldn't find fnames in " + dir);
					}
				}
				getContent(dir + "/fnames", fin_fnames);
			}
		}); // getContent conf
	}
}
@:native("window") extern class GmlExternAPI {
	static var gmlResetOnDefine:Bool;
	static inline function init():Void {
		gmlResetOnDefine = true;
	}
}
typedef GmlLookup = {
	path:String,
	?sub:String,
	row:Int,
	?col:Int
};
typedef GmlConfig = {
	/** Documentation URL, with "$1" to be replaced by search term */
	?helpURL:String,
	/** Documentation index file path (for official documentation) */
	?helpIndex:String,
	/** Additional keywords (if any) */
	?keywords:Array<String>,
	/** Whether to use UK spelling for names */
	?ukSpelling:Bool,
	/** */
	?apiFiles:Array<String>,
	?assetFiles:Array<String>,
};
