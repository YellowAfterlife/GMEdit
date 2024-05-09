package gml;
import ui.preferences.PrefCode;
import electron.FileSystem;
import gml.GmlAPILoader;
import gml.GmlEnum;
import gml.file.GmlFile;
import gml.type.GmlType;
import gml.type.GmlTypeTools;
import haxe.io.Path;
import js.lib.RegExp;
import js.lib.RegExp.RegExpMatch;
import parsers.GmlParseAPI;
import parsers.GmlSeekData.GmlSeekDataHint;
import synext.GmlExtMFunc;
import tools.ArrayMap;
import tools.ChainCall;
import tools.Dictionary;
import ace.AceWrap;
import ace.extern.*;
import tools.JsTools;
import tools.NativeString;
import ui.Preferences;
import ui.liveweb.LiveWeb;
import electron.FileWrap;
import gml.GmlImports;
using tools.ERegTools;
using tools.RegExpTools;
using StringTools;
using tools.NativeString;

/**
 * Stores current API state and project-specific data.
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
		+ "|try|throw|catch|finally"
		+ "|exit|return|wait"
		+ "|enum|var|globalvar|static"
		).split("|"), true
	);
	
	public static var kwCompExprStat:AceAutoCompleteItems = (function() {
		var items = new AceAutoCompleteItems();
		for (kw in [
			"self", "other", "global", "noone"
		]) items.push(new AceAutoCompleteItem(kw, "keyword"));
		return items;
	})();
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
	
	//{ Built-ins
	
	public static var stdDoc:Dictionary<GmlFuncDoc> = new Dictionary();
	public static var stdComp:AceAutoCompleteItems = [];
	public static var stdKind:Dictionary<String> = new Dictionary();
	public static var stdTypeExists:Dictionary<Bool> = new Dictionary();
	
	/** "id.dsmap" -> "ds_map" */
	public static var featherAliases:Dictionary<String> = new Dictionary();
	
	/** Types per built-in variable */
	public static var stdTypes:Dictionary<GmlType> = new Dictionary();
	
	public static var stdInstComp:AceAutoCompleteItems = [];
	public static var stdInstCompMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	public static var stdInstKind:Dictionary<AceTokenType> = new Dictionary();
	public static var stdInstType:Dictionary<GmlType> = new Dictionary();
	
	public static var stdNamespaceDefs:Array<GmlNamespaceDef> = [];
	public static var stdFieldHints:Array<GmlSeekDataHint> = [];
	
	/** for @typedef */
	public static var stdTypedefs:Dictionary<GmlType> = new Dictionary();
	
	public static function stdClear() {
		stdDoc = new Dictionary();
		stdTypes = new Dictionary();
		stdTypeExists = new Dictionary();
		featherAliases = new Dictionary();
		stdComp.clear();
		
		stdInstComp.clear();
		stdInstCompMap = new Dictionary();
		stdInstKind = new Dictionary();
		stdInstType = new Dictionary();
		stdTypedefs = new Dictionary();
		
		stdNamespaceDefs.resize(0);
		stdFieldHints.resize(0);
		
		var sk = new Dictionary();
		for (s in kwList) sk[s] = "keyword";
		
		PrefCode.applyConstKeywords(false, sk);
		
		var kw2 = version.config.additionalKeywords;
		if (kw2 != null) for (s in kw2) sk[s] = "keyword";
		
		if (Preferences.current.importMagic) sk["new"] = "keyword";
		
		if (Preferences.current.castOperators) {
			sk["cast"] = "keyword";
			sk["as"] = "keyword";
		}
		
		sk["true"] = "constant.boolean";
		sk["false"] = "constant.boolean";
		
		for (k in GmlTypeTools.builtinTypes) {
			if (GmlTypeTools.simplenameMap[k]) continue;
			sk[k] = "namespace";
		}
		stdKind = sk;
	}
	
	//}
	
	//{ Extension scope
	
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
	
	//}
	
	//{ Project scope
	
	/** script name -> doc */
	public static var gmlDoc:Dictionary<GmlFuncDoc> = new Dictionary();
	
	/** word -> ACE kind */
	public static var gmlKind:Dictionary<String> = new Dictionary();
	
	/** for global identifiers */
	public static var gmlTypes:Dictionary<GmlType> = new Dictionary();
	
	/** for @typedef */
	public static var gmlTypedefs:Dictionary<GmlType> = new Dictionary();
	
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
	
	public static var gmlGlobalTypes:Dictionary<GmlType> = new Dictionary();
	
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
	
	/**
	 * Asset names for GlobalLookup (Ctrl+T)
	 * NB! If an asset is hidden (e.g. an unlisted extension function), it can be in gmlLookup
	 * but not in here.
	 */
	public static var gmlLookupItems:Array<AceAutoCompleteItem> = [];
	
	/** @hint and other namespaces collected across the code */
	public static var gmlNamespaces:Dictionary<GmlNamespace> = new Dictionary();
	
	public static var gmlNamespaceComp:ArrayMap<AceAutoCompleteItem> = new ArrayMap();
	
	public static function ensureNamespace(name:String, ?opt:GmlEnsureNamespaceOptions):GmlNamespace {
		var ns = gmlNamespaces[name];
		if (ns == null) {
			ns = new GmlNamespace(name);
			gmlNamespaces[name] = ns;
			gmlNamespaceComp[name] = new AceAutoCompleteItem(name, "namespace");
			if (!gmlKind.exists(name) && !stdKind.exists(name) && opt?.setKind != false) gmlKind[name] = "namespace";
			if (name == "instance" || name == "object") ns.isObject = true;
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
		gmlTypes = new Dictionary();
		gmlTypedefs = new Dictionary();
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
		gmlGlobalTypes = new Dictionary();
		gmlGlobalFullComp.clear();
		gmlInstFieldMap = new Dictionary();
		gmlInstFieldComp.clear();
		gmlLookup = new Dictionary();
		gmlLookupItems.resize(0);
		gmlNamespaces = new Dictionary();
		gmlNamespaceComp.clear();
		for (type in gmx.GmxLoader.assetTypes) {
			gmlAssetIDs.set(type, new Dictionary());
		}
		for (k in GmlTypeTools.builtinTypes) {
			var ns = ensureNamespace(k, {
				setKind: !GmlTypeTools.simplenameMap[k]
			});
			ns.canCastToStruct = ns.name == "struct";
			ns.noTypeRef = true;
		}
		for (hint in stdFieldHints) {
			var ns = GmlAPI.ensureNamespace(hint.namespace);
			ns.noTypeRef = true;
			ns.addFieldHint(hint.field, hint.isInst, hint.comp, hint.doc, hint.type);
		}
		for (pair in stdNamespaceDefs) {
			var name = pair.name;
			var ns = gmlNamespaces[name];
			if (ns == null) {
				ns = new GmlNamespace(name);
				gmlNamespaces[name] = ns;
				gmlNamespaceComp[name] = new AceAutoCompleteItem(name, "namespace");
				if (name == "instance" || name == "object") ns.isObject = true;
			}
			ns.canCastToStruct = false;
			ns.noTypeRef = true;
			for (parent in pair.parents) {
				if (ns.procSpecialInterfaces(parent, true)) continue;
				if (ns.parent != null) Console.warn('Re-assigning parent for ${pair.name}');
				ns.parent = gmlNamespaces[parent];
				if (ns.parent != null) {
					ns.canCastToStruct = ns.parent.canCastToStruct;
				} else Console.warn('Parent ${parent} is missing for ${pair.name}');
			}
			if (!ns.avoidHighlight) stdKind[name] = "namespace";
		}
		gml.type.GmlTypeParser.clear();
	}
	
	//}
	
	//
	public static function init() {
		GmlAPILoader.init();
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
class GmlNamespaceDef {
	public var name:String;
	public var parents:Array<String>;
	public function new() {}
}
typedef GmlEnsureNamespaceOptions = {
	?setKind:Bool,
};