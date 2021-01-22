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
		
		fileSessionTime: 7,
		projectSessionTime: 14,
		singleClickOpen: false,
		taskbarOverlays: false,
		assetThumbs: true,
		clearAssetThumbsOnRefresh: true,
		showGMLive: Everywhere,
		codeLiterals: false,
		ctrlWheelFontSize: true,
		fileChangeAction: Ask,
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
	
	assetThumbs:Bool,
	clearAssetThumbsOnRefresh:Bool,
	singleClickOpen:Bool,
	taskbarOverlays:Bool,
	showGMLive:PrefGMLive,
	fileChangeAction:PrefFileChangeAction,
	closeTabsOnFileDeletion:Bool,
	recentProjectCount:Int,
	//
	ukSpelling:Bool,
	?compExactMatch:Bool, // deprecated
	compMatchMode:PrefMatchMode,
	compKeywords:Bool,
	compFilterSnippets:Bool,
	
	detectTab:Bool,
	tabSize:Int,
	tabSpaces:Bool,
	tooltipKind:PrefTooltipKind,
	tooltipDelay:Int,
	tooltipKeyboardDelay:Int,
	codeLiterals:Bool,
	ctrlWheelFontSize:Bool,
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
}
@:enum abstract PrefTooltipKind(Int) from Int to Int {
	var None = 0;
	var Custom = 1;
}
@:enum abstract PrefFileChangeAction(Int) from Int to Int {
	var Nothing = 0;
	var Ask = 1;
	var Reload = 2;
}
@:enum abstract PrefGMLive(Int) from Int to Int {
	var Nowhere = 0;
	var ItemsOnly = 1;
	var Everywhere = 2;
	public inline function isActive():Bool {
		return this > 0;
	}
}
