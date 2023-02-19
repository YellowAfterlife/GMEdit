package gml;
import js.lib.RegExp;
import tools.Dictionary;

/**
 * A typedef for versions' JSON files describing supported features and so on.
 * @author YellowAfterlife
 */
typedef GmlVersionConfig = {
	/**
	 * Name of parent API configuration to inherit from.
	 * This is required for your configuration to be future-proof
	 * (that is, don't break when more options are introduced)
	 * "gml1" and "gml2" are treated as special cases
	 * and will fill out code-only settings for GMS1/GMS2 accordingly
	 */
	var parent:String;
	
	/** Display name */
	var name:String;
	
	/** Whether you can do "a \" b" */
	var hasStringEscapeCharacters:Bool;
	
	/** Whether @"" and @'' are allowed */
	var hasLiteralStrings:Bool;
	
	/** Whether `health: ${hp}/${maxhp}` is allowed */
	var hasTemplateStrings:Bool;
	
	/** Whether 'text' is allowed */
	var hasSingleQuotedStrings:Bool;
	
	/** Whether `a ? b : c` is supported */
	var hasTernaryOperator:Bool;
	
	/** Whether `#RrGgBbb` is allowed */
	var hasColorLiterals:Bool;
	
	/** Whether scr_some.stativar is allowed */
	var hasScriptDotStatic:Bool;
	
	/** Whether GMS2 style `/// @meta` docs are used */
	var hasJSDoc:Bool;
	
	/** Additional keywords (if any) */
	var additionalKeywords:Array<String>;
	
	/** Filled out from above for quick lookups */
	var ?additionalKeywordsMap:Dictionary<Bool>;
	
	/** Whether you can do `#define name(a, b)` */
	var hasDefineArgs:Bool;
	
	/** Whether to restart the line numbers whenever finding a #define/#event/etc. */
	var resetLineCounterOnDefine:Bool;
	
	/** Whether #region ... #endregion are supported */
	var hasRegions:Bool;
	
	/** Whether events can have #section splitters */
	var hasEventSections:Bool;
	
	/** Whether events can have #action magic */
	var hasEventActions:Bool;
	
	/** Whether #pragma is a thing */
	var hasPragma:Bool;
	
	/** If set to "gms1", auto-maps colour<->color */
	var docMode:String;
	
	/** Used for magic and other features */
	var projectMode:String;
	
	/**
	 * Used to shortcut some checks in project handling code.
	 * This is set automatically based on `projectMode` in `GmlVersion.init`
	 */
	var ?projectModeId:GmlVersionProjectModeId;
	
	/** If specified, will be used on a directory-less path to detect project version */
	var projectRegex:String;
	
	var ?projectRegexCached:RegExp;
	
	/** If specified, overrides what counts as a code file for RawLoader (e.g. ["gml", "ntgml"]) */
	var ?gmlExtensions:Array<String>;
	
	/**
	 * 
	 * "local": Per-file (e.g. NTT mods)
	 * "directory": For all files inside same directory (as if they are scripts)
	 * "gms1": GameMaker Studio 1 indexer
	 * "gms2": GameMaker Studio 2 indexer
	 */
	var indexingMode:GmlVersionConfigIndexingMode;
	
	
	var loadingMode:String;
	
	
	var searchMode:String;
	
	/**
	 * Files to load API definitions from.
	 * If not specified, uses the built-in schema
	 * ("api.gml" + "replace.gml" + "exclude.gml" + "extra.gml")
	 */
	var ?apiFiles:Array<String>;
	
	/** Additional replace files over above */
	var ?patchFiles:Array<String>;
	
	/**
	 * Files to load asset names from.
	 * This is only needed if your API config has it's own built-ins
	 * (e.g. is a modding API and thus there are game's base assets)
	 */
	var ?assetFiles:Array<String>;
	
	/** Documentation URL, with "$1" to be replaced by search term */
	var helpURL:String;
	
	/** Documentation index file path (for official documentation) */
	var helpIndex:String;
}
enum abstract GmlVersionProjectModeId(Int) from Int to Int {
	var Other = 0;
	var GMS1 = 1;
	var GMS2 = 2;
	var GmkSplitter = -81;
}
enum abstract GmlVersionConfigIndexingMode(String) {
	var GMS1 = "gms1";
	var GMS2 = "gms2";
	var Local = "local";
	var Directory = "directory";
}
class GmlVersionConfigDefaults {
	public static function get(v2:Bool):GmlVersionConfig {
		var v1 = !v2;
		return {
			parent: null,
			name: null,
			//
			hasStringEscapeCharacters: v2,
			hasLiteralStrings: v2,
			hasSingleQuotedStrings: v1,
			hasTernaryOperator: v2,
			hasTemplateStrings: false,
			hasDefineArgs: false,
			hasRegions: v2,
			hasEventSections: v1,
			hasEventActions: v1,
			hasColorLiterals: v2,
			hasScriptDotStatic: v2,
			hasPragma: false,
			//
			resetLineCounterOnDefine: true,
			hasJSDoc: v2,
			helpURL: null,
			helpIndex: null,
			//
			indexingMode: Directory,
			loadingMode: "directory",
			searchMode: "directory",
			projectMode: null,
			docMode: null,
			projectRegex: null,
			//
			additionalKeywords: null,
			apiFiles: null,
			assetFiles: null,
		};
	}
}
