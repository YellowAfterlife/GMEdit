package gml;
import electron.FileSystem;
import gml.GmlEnum;
import haxe.io.Path;
import js.RegExp;
import tools.Dictionary;
import ace.AceWrap;
import tools.NativeString;
using tools.ERegTools;

/**
 * ...
 * @author YellowAfterlife
 */
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
	public static var stdDoc:Dictionary<GmlFuncDoc> = new Dictionary();
	public static var stdComp:AceAutoCompleteItems = [];
	public static var stdKind:Dictionary<String> = new Dictionary();
	public static function stdClear() {
		stdDoc = new Dictionary();
		stdComp.clear();
		var q = new Dictionary();
		for (kw in kwList) q.set(kw, "keyword");
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
	public static var gmlDoc:Dictionary<GmlFuncDoc> = new Dictionary();
	public static var gmlKind:Dictionary<String> = new Dictionary();
	public static var gmlComp:AceAutoCompleteItems = [];
	public static var gmlEnums:Dictionary<GmlEnum> = new Dictionary();
	public static var gmlGlobalKind:Dictionary<String> = new Dictionary();
	public static var gmlGlobalMap:Dictionary<String> = new Dictionary();
	public static var gmlAssetIDs:Dictionary<Dictionary<Int>> = new Dictionary();
	public static function gmlClear() {
		gmlDoc = new Dictionary();
		gmlKind = new Dictionary();
		gmlComp.clear();
		gmlEnums = new Dictionary();
		gmlGlobalKind = new Dictionary();
		gmlAssetIDs = new Dictionary();
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
		~/^((\w+)\((.*?)\))([~\$]*);?[ \t]*$/gm.each(src, function(rx:EReg) {
			var comp = rx.matched(1);
			var name = rx.matched(2);
			var args = rx.matched(3);
			var kind = rx.matched(4);
			//
			stdKind.set(name, "function");
			stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: "function",
				doc: comp
			});
			stdDoc.set(name, parseDoc(comp));
		});
		// 1name 2array       3flags
		~/^((\w+)(\[[^\]]*\])?([~\*\$#]*));?[ \t]*$/gm.each(src, function(rx:EReg) {
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
	}
	//
	public static function parseDoc(s:String):GmlFuncDoc {
		var p0 = s.indexOf("(");
		var p1 = s.indexOf(")", p0);
		if (p0 >= 0 && p1 >= 0) {
			var sw = s.substring(p0 + 1, p1);
			return {
				pre: s.substring(0, p0 + 1),
				post: s.substring(p1),
				args: NativeString.split(sw, untyped __js__("/,\\s*/g")),
				rest: sw.indexOf("...") >= 0,
			};
		} else return {
			pre: s,
			post: "",
			args: [],
			rest: false,
		};
	}
	//
	public static function init() {
		stdClear();
		if (version == GmlVersion.none) return;
		//
		var getContent_s:String;
		var getContent_rx = new RegExp("\r\n", "g");
		inline function getContent(path:String):String {
			getContent_s = FileSystem.readFileSync(Path.join([Main.modulePath, path]), "utf8");
			getContent_s = NativeString.replace(getContent_s, getContent_rx, "\n");
			return getContent_s;
		}
		var dir = "./api/" + version.getName();
		//
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
typedef GmlFuncDoc = {
	pre:String, post:String, args:Array<String>, rest:Bool
};
