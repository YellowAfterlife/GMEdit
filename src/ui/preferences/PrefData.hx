package ui.preferences;
import haxe.DynamicAccess;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract PrefData(PrefDataImpl) from PrefDataImpl to PrefDataImpl {
	public static function defValue():PrefData return {
		theme: "dark",
		ukSpelling: false,
		apiFeatureFlags: [],
		compMatchMode: PrefMatchMode.AceSmart,
		compKeywords: true,
		compFilterSnippets: true,
		
		argsMagic: true,
		argsFormat: "",
		argsStrict: false,
		importMagic: true,
		allowImportUndo: false,
		coroutineMagic: true,
		lambdaMagic: true,
		hyperMagic: true,
		mfuncMagic: true,
		nullCoalescingAssignment: true,
		castOperators: true,
		hashColorLiterals: true,
		arrowFunctions: true,
		showGMLive: Everywhere,
		
		fileSessionTime: 7,
		projectSessionTime: 14,
		singleClickOpen: false,
		taskbarOverlays: false,
		assetThumbs: true,
		assetCache: false,
		assetIndexBatchSize: 128,
		diskAssetCache: {
			enabled: false,
			maxSizePerItem: 4096,
			minItemCount: 512,
			cacheUpdateThreshold: 15,
			fileExtensions: ["gml", "yy", "gmx"],
		},
		clearAssetThumbsOnRefresh: true,
		codeLiterals: false,
		constKeywords: false,
		ctrlWheelFontSize: true,
		showArgTypesInStatusBar: false,
		
		fileChangeAction: Ask,
		avoidYyChanges: false,
		closeTabsOnFileDeletion: true,
		backupCount: { v1: 2, v2: 0, live: 0 },
		recentProjectCount: 16,
		tabSize: 4,
		tabSpaces: true,
		detectTab: true,
		eventOrder: 1,
		assetOrder23: Custom,
		extensionAPIOrder: 1,
		tooltipDelay: 350,
		tooltipKeyboardDelay: 0,
		tooltipKind: Custom,
		linterPrefs: {},
		customizedKeybinds: {},
		
		app: {
			windowWidth: 960,
			windowHeight: 720,
			windowFrame: false,
		},
		globalLookup: {
			matchMode: AceSmart,
			maxCount: 100,
			initialWidth: 480,
			initialHeight: 384,
			initialFilters: {},
		},
		chromeTabs: {
			minWidth: 50,
			maxWidth: 160,
			multiline: false,
			fitText: false,
			boxyTabs: false,
			flowAroundSystemButtons: false,
			autoHideCloseButtons: false,
			rowBreakAfterPinnedTabs: false,
			lockPinnedTabs: false,
			multilineStretchStyle: 1,
			idleTime: 0,
			pinLayers: false,
		},
	};
}
typedef PrefDataImpl = {
	theme:String,
	fileSessionTime:Float,
	projectSessionTime:Float,
	
	argsMagic:Bool,
	argsFormat:String,
	argsStrict:Bool,
	importMagic:Bool,
	allowImportUndo:Bool,
	coroutineMagic:Bool,
	lambdaMagic:Bool,
	hyperMagic:Bool,
	mfuncMagic:Bool,
	nullCoalescingAssignment:Bool,
	castOperators:Bool,
	hashColorLiterals:Bool,
	arrowFunctions:Bool,
	
	assetThumbs:Bool,
	assetCache:Bool,
	assetIndexBatchSize:Int,
	clearAssetThumbsOnRefresh:Bool,
	singleClickOpen:Bool,
	taskbarOverlays:Bool,
	showGMLive:PrefGMLive,
	
	avoidYyChanges:Bool,
	fileChangeAction:PrefFileChangeAction,
	closeTabsOnFileDeletion:Bool,
	recentProjectCount:Int,
	//
	ukSpelling:Bool,
	?compExactMatch:Bool, // deprecated
	compMatchMode:PrefMatchMode,
	compKeywords:Bool,
	compFilterSnippets:Bool,
	apiFeatureFlags:Array<String>,
	
	detectTab:Bool,
	tabSize:Int,
	tabSpaces:Bool,
	tooltipKind:PrefTooltipKind,
	tooltipDelay:Int,
	tooltipKeyboardDelay:Int,
	codeLiterals:Bool,
	constKeywords:Bool,
	ctrlWheelFontSize:Bool,
	showArgTypesInStatusBar:Bool,
	//
	eventOrder:Int,
	assetOrder23:PrefAssetOrder23,
	extensionAPIOrder:Int,
	backupCount:DynamicAccess<Int>,
	linterPrefs:parsers.linter.GmlLinterPrefs,
	//
	?gmkSplitPath:String,
	?gmkSplitOpenExisting:Bool,
	
	/** section -> commandName -> keybinds */
	customizedKeybinds:DynamicAccess<DynamicAccess<Array<String>>>,
	
	app: {
		windowWidth:Int,
		windowHeight:Int,
		windowFrame:Bool,
	},
	globalLookup: {
		matchMode:PrefMatchMode,
		maxCount:Int,
		initialWidth:Int,
		initialHeight:Int,
		initialFilters:DynamicAccess<Bool>,
	},
	diskAssetCache: {
		var enabled:Bool;
		var minItemCount:Int;
		var maxSizePerItem:Int;
		/** in %! **/
		var cacheUpdateThreshold:Float;
		var fileExtensions:Array<String>;
	},
	chromeTabs: {
		minWidth:Int,
		maxWidth:Int,
		multiline:Bool,
		fitText:Bool,
		boxyTabs:Bool,
		flowAroundSystemButtons:Bool,
		autoHideCloseButtons:Bool,
		rowBreakAfterPinnedTabs:Bool,
		
		/** if locked, pinned tabs cannot be closed except through context menu */
		lockPinnedTabs:Bool,
		
		/** time until the tab gets grayed out, in seconds */
		idleTime:Int,
		/** 0: don't, 1: stretch all, 2: stretch last */
		multilineStretchStyle:Int,
		pinLayers:Bool,
	},
}
enum abstract PrefAssetOrder23(Int) from Int to Int {
	var Custom = 0;
	var Ascending = 1;
	var Descending = 2;
}
enum abstract PrefMatchMode(Int) from Int to Int {
	/// GMS1 style
	var StartsWith = 0;
	/// GMS2 style, "debug" for "show_[debug]_message"
	var Includes = 1;
	/// "icl" for "[i]o_[cl]ear"
	var AceSmart = 2;
	/// "icl" for "[i]nstance_[c]reate_[l]ayer"
	var SectionStart = 3;
	public static var names:Array<String> = [
		"Start of string (GMS1 style)",
		"Containing (GMS2 style)",
		"Smart (`icl` -> `io_clear`)",
		"Per-section (`icl` -> `instance_create_layer`)",
	];
}
enum abstract PrefTooltipKind(Int) from Int to Int {
	var None = 0;
	var Custom = 1;
}
enum abstract PrefFileChangeAction(Int) from Int to Int {
	var Nothing = 0;
	var Ask = 1;
	var Reload = 2;
}
enum abstract PrefGMLive(Int) from Int to Int {
	var Nowhere = 0;
	var ItemsOnly = 1;
	var Everywhere = 2;
	public inline function isActive():Bool {
		return this > 0;
	}
}
