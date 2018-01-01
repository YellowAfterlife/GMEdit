package gml;
import electron.FileSystem;
import gml.GmlEnum;
import haxe.io.Path;
import js.RegExp;
import tools.Dictionary;
import ace.AceWrap;
import tools.NativeString;
import ui.Preferences;
using tools.ERegTools;
using StringTools;

/**
 * ...
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
		"mod", "div", "not", "and", "or", "xor", "enum"
	];
	public static var kwMap:Dictionary<Bool> = new Dictionary();
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
		var q = new Dictionary();
		for (kw in kwList) q.set(kw, "keyword");
		if (version == GmlVersion.live) {
			q.set("wait", "keyword");
			q.set("in", "keyword");
			q.set("try", "keyword");
			q.set("catch", "keyword");
			q.set("throw", "keyword");
		}
		stdKind = q;
	}
	// extension scope
	public static var extDoc:Dictionary<GmlFuncDoc> = new Dictionary();
	public static var extKind:Dictionary<String> = new Dictionary();
	public static var extComp:AceAutoCompleteItems = [];
	public static function extClear() {
		extDoc = new Dictionary();
		extKind = new Dictionary();
		extComp.clear();
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
	
	/** asset type -> asset name -> id*/
	public static var gmlAssetIDs:Dictionary<Dictionary<Int>> = new Dictionary();
	
	/** asset name -> asset AC */
	public static var gmlAssetComp:Dictionary<AceAutoCompleteItem> = new Dictionary();
	
	/** Used for F12/middle-click */
	public static var gmlLookup:Dictionary<GmlLookup> = new Dictionary();
	
	/** `\n` separated asset names for regular expression search */
	public static var gmlLookupText:String = "";
	
	public static function gmlClear() {
		gmlDoc = new Dictionary();
		gmlKind = new Dictionary();
		gmlComp.clear();
		gmlEnums = new Dictionary();
		gmlAssetIDs = new Dictionary();
		gmlAssetComp = new Dictionary();
		gmlLookup = new Dictionary();
		gmlLookupText = "";
		for (type in gmx.GmxLoader.assetTypes) {
			gmlAssetIDs.set(type, new Dictionary());
		}
	}
	//
	
	/**
	 * Loads definitions from fnames format used by GMS itself.
	 */
	public static function loadStd(src:String) {
		//  1func (2args ) 3flags
		~/^(:?(\w+)\((.*?)\))([~\$#*@&£!:]*);?[ \t]*$/gm.each(src, function(rx:EReg) {
			var comp = rx.matched(1);
			var name = rx.matched(2);
			var args = rx.matched(3);
			var flags:String = rx.matched(4);
			var show = true;
			var doc = parseDoc(comp);
			if (version == GmlVersion.v2) {
				if (ukSpelling) {
					if (flags.indexOf("$") >= 0) show = false;
				} else {
					if (flags.indexOf("£") >= 0) show = false;
				}
			} else if (!ukSpelling) {
				var orig = name;
				// (todo: were there other things?)
				name = NativeString.replaceExt(name, "colour", "color");
				if (orig != name) {
					stdKind.set(orig, "function");
					stdDoc.set(name, doc);
				}
			}
			//
			if (stdKind.exists(name)) return;
			stdKind.set(name, "function");
			if (show) stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: "function",
				doc: comp
			});
			stdDoc.set(name, doc);
		});
		// 1name 2array       3flags         type
		~/^((\w+)(\[[^\]]*\])?([~\*\$£#@&]*))(?::\w+)?;?[ \t]*$/gm.each(src, function(rx:EReg) {
			var comp = rx.matched(1);
			var name = rx.matched(2);
			var flags = rx.matched(4);
			var kind:String;
			if (flags.indexOf("#") >= 0) {
				kind = "constant";
			} else kind = "variable";
			//if (rx.matched(3) != null) kind += "[]";
			stdKind.set(name, kind);
			stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: kind,
				doc: comp
			});
		});
		// name       =      value
		~/^(\w+)[ \t]*=[ \t]*(.+)$/g.each(src, function(rx:EReg) {
			var name = rx.matched(1);
			var expr = rx.matched(2);
			stdKind.set(name, "constant");
			stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: "constant",
				doc: expr
			});
		});
	}
	
	public static function loadAssets(src:String) {
		~/(\w+)/g.each(src, function(rx:EReg) {
			var name = rx.matched(1);
			stdKind.set(name, "asset");
			stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: "asset",
				doc: null,
			});
		});
	}
	//
	public static function parseDoc(s:String, ?out:GmlFuncDoc):GmlFuncDoc {
		var p0 = s.indexOf("(");
		var p1 = s.indexOf(")", p0);
		var pre:String, post:String, args:Array<String>, rest:Bool;
		if (p0 >= 0 && p1 >= 0) {
			var sw = s.substring(p0 + 1, p1);
			pre = s.substring(0, p0 + 1);
			post = s.substring(p1);
			args = NativeString.splitReg(sw, untyped __js__("/,\\s*/g"));
			rest = sw.indexOf("...") >= 0;
		} else {
			pre = s;
			post = "";
			args = [];
			rest = false;
		}
		if (out != null) {
			out.pre = pre;
			out.post = post;
			out.args = args;
			out.rest = rest;
			return out;
		} else return { pre: pre, post: post, args: args, rest: rest };
	}
	//
	public static function init() {
		stdClear();
		untyped window.gmlResetOnDefine = version != GmlVersion.live;
		if (version == GmlVersion.none) return;
		//
		var getContent_s:String;
		var getContent_rx = new RegExp("\r\n", "g");
		inline function getContent(path:String):String {
			getContent_s = FileSystem.readFileSync(Main.relPath(path), "utf8");
			getContent_s = NativeString.replaceExt(getContent_s, getContent_rx, "\n");
			return getContent_s;
		}
		var dir = "api/" + version.getName();
		//
		helpURL = null;
		helpLookup = null;
		ukSpelling = Preferences.current.ukSpelling;
		var confPath = Main.relPath(dir + "/config.json");
		var files:Array<String> = null;
		var assets:Array<String> = null;
		if (FileSystem.existsSync(confPath)) {
			var conf:GmlConfig = FileSystem.readJsonFileSync(confPath);
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
				var helpIndexJs = FileSystem.readTextFileSync(helpIndexPath);
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
			}
		}
		//
		if (assets != null) for (file in assets) {
			var raw = getContent('$dir/$file');
			loadAssets(raw);
		}
		//
		if (files != null) for (file in files) {
			var raw = getContent('$dir/$file');
			loadStd(raw);
		} else {
			var raw = getContent('$dir/fnames');
			raw += "\n" + getContent('$dir/extra.gml');
			//
			var replace = getContent('$dir/replace.gml');
			~/^(\w+).+$/gm.each(replace, function(rx:EReg) {
				var name = rx.matched(1);
				var code = rx.matched(0);
				raw = (new EReg('^$name.+$$', "gm")).map(raw, function(r1) {
					return code;
				});
			});
			//
			var exclude = getContent('$dir/exclude.gml');
			~/^(\w+)(\*?)$/gm.each(exclude, function(rx:EReg) {
				var name = rx.matched(1);
				if (rx.matched(2) != "") {
					raw = new EReg('^$name.*$', "gm").replace(raw, "");
				} else {
					raw = new EReg('^$name\\b.*$', "gm").replace(raw, "");
				}
			});
			//
			loadStd(raw);
		}
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
typedef GmlFuncDoc = {
	pre:String, post:String, args:Array<String>, rest:Bool
};
