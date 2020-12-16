package gml;
import electron.FileSystem;
import gml.GmlEnum;
import gml.file.GmlFile;
import haxe.io.Path;
import js.lib.RegExp;
import parsers.GmlParseAPI;
import synext.GmlExtMFunc;
import tools.ArrayMap;
import tools.ChainCall;
import tools.Dictionary;
import ace.AceWrap;
import ace.extern.*;
import tools.NativeString;
import ui.Preferences;
import ui.liveweb.LiveWeb;
import electron.FileWrap;
import gml.GmlImports;
using tools.ERegTools;
using StringTools;

/**
 * Stores current API state and projct-specific data.
 * @author YellowAfterlife
 */
@:expose("GmlAPI")
class GmlAPI {
	public static var version(default, set):GmlVersion = GmlVersion.none;
	private static function set_version(v:GmlVersion):GmlVersion {
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
	
	public static var kwCompStat:AceAutoCompleteItems = (function() {
		var items = new AceAutoCompleteItems();
		for (kw in [
			"if", "else",
			"for", "while", "do", "until", "repeat", "with", "break", "continue",
			"switch", "case", "default",
			"exit", "return",
			"var", "globalvar",
		]) items.push(new AceAutoCompleteItem(kw, "keyword"));
		return items;
	})();
	//
	public static var scopeResetRx = new RegExp('^(?:#define|#event|#moment|#target|function)[ \t]+([\\w:]+)', '');
	public static var scopeResetRxNF = new RegExp('^(?:#define|#event|#moment|#target)[ \t]+([\\w:]+)', '');
	//
	public static var helpLookup:Dictionary<String> = null;
	public static var helpURL:String = null;
	public static var ukSpelling:Bool = false;
	//
	public static var forceTemplateStrings:Bool = false;
	//
	public static var stdDoc:Dictionary<GmlFuncDoc> = new Dictionary();
	public static var stdComp:AceAutoCompleteItems = [];
	public static var stdInstComp:AceAutoCompleteItems = [];
	public static var stdKind:Dictionary<String> = new Dictionary();
	public static function stdClear() {
		stdDoc = new Dictionary();
		stdComp.clear();
		stdInstComp.clear();
		var sk = new Dictionary();
		inline function add(s:String) {
			sk.set(s, "keyword");
		}
		for (s in kwList) add(s);
		var kw2 = version.config.additionalKeywords;
		if (kw2 != null) for (s in kw2) add(s);
		if (Preferences.current.importMagic) add("new");
		stdKind = sk;
	}
	// extension scope
	public static var extDoc:Dictionary<GmlFuncDoc> = new Dictionary();
	public static var extKind:Dictionary<String> = new Dictionary();
	public static var extComp:AceAutoCompleteItems = [];
	/** declared argument counts per extension function, for linter */
	public static var extArgc:Dictionary<Int> = new Dictionary();
	public static var extCompMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	public static function extCompAdd(comp:AceAutoCompleteItem) {
		if (!extCompMap.exists(comp.name)) {
			extCompMap.set(comp.name, comp);
			extComp.push(comp);
		}
	}
	public static function extClear() {
		extDoc = new Dictionary();
		extKind = new Dictionary();
		extComp.clear();
		extCompMap = new Dictionary();
		extArgc = new Dictionary();
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
	
	/** auto-complete items for enums themselves (for v:type) */
	public static var gmlEnumTypeComp:AceAutoCompleteItems = [];
	
	/** macro name -> macro */
	public static var gmlMacros:Dictionary<GmlMacro> = new Dictionary();
	
	/** mfunc name -> mfunc */
	public static var gmlMFuncs:Dictionary<GmlExtMFunc> = new Dictionary();
	
	/** asset type -> asset name -> id*/
	public static var gmlAssetIDs:Dictionary<Dictionary<Int>> = new Dictionary();
	
	/** asset name -> asset AC */
	public static var gmlAssetComp:Dictionary<AceAutoCompleteItem> = new Dictionary();
	
	/** global field name -> data */
	public static var gmlGlobalFieldMap:Dictionary<GmlGlobalField> = new Dictionary();
	
	/** global field AC items */
	public static var gmlGlobalFieldComp:AceAutoCompleteItems = [];
	
	/** ditto but has "global." prefix */
	public static var gmlGlobalFullMap:Dictionary<GmlGlobalField> = new Dictionary();
	
	/** ditto but has "global." prefix */
	public static var gmlGlobalFullComp:AceAutoCompleteItems = [];
	
	/** instance variables */
	public static var gmlInstFieldMap:Dictionary<GmlField> = new Dictionary();
	
	/** instance variable auto-completion */
	public static var gmlInstFieldComp:AceAutoCompleteItems = [];
	
	/** Used for F12/middle-click */
	public static var gmlLookup:Dictionary<GmlLookup> = new Dictionary();
	
	/** `\n` separated asset names for regular expression search */
	public static var gmlLookupText:String = "";
	
	/** @hint and other namespaces collected across the code */
	public static var gmlNamespaces:Dictionary<GmlNamespace> = new Dictionary();
	
	public static var gmlNamespaceComp:ArrayMap<AceAutoCompleteItem> = new ArrayMap();
	
	public static function ensureNamespace(name:String):GmlNamespace {
		var ns = gmlNamespaces[name];
		if (ns == null) {
			ns = new GmlNamespace(name);
			gmlNamespaces[name] = ns;
			gmlNamespaceComp[name] = new AceAutoCompleteItem(name, "namespace");
			if (!gmlKind.exists(name)) gmlKind[name] = "namespace";
		}
		return ns;
	}
	
	#if lwedit
	/** Function name -> min. argument count */
	public static var lwArg0:Dictionary<Int> = new Dictionary();
	
	/** Function name -> max. argument count */
	public static var lwArg1:Dictionary<Int> = new Dictionary();
	
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
		gmlEnumTypeComp.clear();
		gmlMacros = new Dictionary();
		gmlMFuncs = new Dictionary();
		gmlAssetIDs = new Dictionary();
		gmlAssetComp = new Dictionary();
		gmlGlobalFieldMap = new Dictionary();
		gmlGlobalFieldComp.clear();
		gmlGlobalFullMap = new Dictionary();
		gmlGlobalFullComp.clear();
		gmlInstFieldMap = new Dictionary();
		gmlInstFieldComp.clear();
		gmlLookup = new Dictionary();
		gmlLookupText = "";
		gmlNamespaces = new Dictionary();
		gmlNamespaceComp.clear();
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
				var rp = path;
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
		var dir = version.dir;
		//
		helpURL = null;
		helpLookup = null;
		ukSpelling = Preferences.current.ukSpelling;
		//
		var conf:GmlVersionConfig = version.config;
		var files = conf.apiFiles;
		var assets = conf.assetFiles;
		//
		var confKeywords = conf.additionalKeywords;
		if (confKeywords != null) for (kw in confKeywords) {
			stdKind.set(kw, "keyword");
		}
		//
		helpURL = conf.helpURL;
		var helpIndexPath = conf.helpIndex;
		if (helpIndexPath != null) {
			helpIndexPath = dir + "/" + helpIndexPath;
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
			instComp: stdInstComp,
			ukSpelling: ukSpelling,
			version: version,
			#if lwedit
			lwArg0: lwArg0,
			lwArg1: lwArg1,
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
			var cx = new ChainCall();
			cx.call(getContent, dir + "/fnames", function(s:String){
				if (s != null) {
					raw = s;
				} else {
					Main.window.alert("Couldn't find fnames in " + dir);
					cx.stop();
				}
			}).call(getContent, dir + "/extra.gml", function(s:String) {
				// whatever missing in fnames
				if (s != null && s != "") raw += "\n" + s;
				#if lwedit
				raw += "\ntrace(...)";
				#end
			}).call(getContent, dir + "/replace.gml", function(s:String) {
				// various corrections instead of editing fnames by hand
				if (s != null) ~/^(\w+).+$/gm.each(s, function(rx:EReg) {
					var name = rx.matched(1);
					var code = rx.matched(0);
					raw = (new EReg('^$name\\b.*$$', "gm")).map(raw, function(r1) {
						return code;
					});
				});
			}).call(getContent, dir + '/exclude.gml', function(s:String) {
				// deprecated and/or forbidden
				if (s != null) ~/^(\w+)(\*?)$/gm.each(s, function(rx:EReg) {
					var name = rx.matched(1);
					if (rx.matched(2) != "") {
						raw = new EReg('^$name.*$', "gm").replace(raw, "");
					} else {
						raw = new EReg('^$name\\b.*$', "gm").replace(raw, "");
					}
				});
			}).call(getContent, dir + '/inst.gml', function(s:String) {
				// mark functions that need self-context
				if (s != null) ~/^(\w+)$/gm.each(s, function(rx:EReg) {
					var name = rx.matched(1);
					raw = new EReg('^$name\\b', "gm").replace(raw, ":" + name);
				});
			}).call(getContent, dir + '/noret.gml', function(s:String) {
				// concat customizations:
				#if !lwedit
				if (FileSystem.canSync) {
					var xdir = FileWrap.userPath + "/api/" + version.getName();
					if (FileSystem.existsSync(xdir))
					for (xrel in FileSystem.readdirSync(xdir)) {
						var xfull = xdir + "/" + xrel;
						try {
							raw += "\n" + FileSystem.readTextFileSync(xfull);
						} catch (x:Dynamic) {
							Main.console.error("Error loading API from " + xfull, x);
						}
					}
				}
				#end
				GmlParseAPI.loadStd(raw, data);
				
				// patch non-returning functions:
				if (s != null) ~/^(\w+)$/gm.each(s, function(rx:EReg) {
					var name = rx.matched(1);
					var doc = GmlAPI.stdDoc[name];
					if (doc != null) doc.hasReturn = false;
				});
				
				// give GMLive a copy of data
				#if lwedit
				if (lwArg0 != null) {
					if (LiveWeb.api != null) {
						#if 1
						var arr = [];
						for (k => v in lwArg0) {
							arr.push(k + ":" + v + ":" + lwArg1[k]);
						}
						var init = '{\nlwArgs:"' + arr.join("|") + '",\n';
						//
						arr = [];
						for (k => f in lwFlags) arr.push(k + ":" + f);
						init += 'lwFlags:"' + arr.join("|") + '",\n';
						//
						arr = [];
						for (k => _ in lwConst) arr.push(k);
						init += 'lwConst:"' + arr.join("|") + '",\n';
						//
						arr = [];
						for (k => _ in lwInst) arr.push(k);
						init += 'lwInst:"' + arr.join("|") + '"\n';
						//
						init += "}";
						Main.console.log(init);
						#end
						LiveWeb.api.setAPI(data);
					}
					Main.window.setTimeout(function() {
						LiveWeb.readyUp();
					});
				}
				
				// force [re-]tokenization so that the welcome page highlights correctly:
				Main.aceEditor.session.bgTokenizer.start(0);
				#end
			});
		}
		//}); // getContent conf
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
