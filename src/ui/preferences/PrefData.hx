package ui.preferences;
import haxe.DynamicAccess;

/**
 * ...
 * @author YellowAfterlife
 */
typedef PrefData = {
	theme:String,
	ukSpelling:Bool,
	?compExactMatch:Bool, // deprecated
	compMatchMode:PrefMatchMode,
	fileSessionTime:Float,
	projectSessionTime:Float,
	argsMagic:Bool,
	argsFormat:String,
	importMagic:Bool,
	allowImportUndo:Bool,
	coroutineMagic:Bool,
	lambdaMagic:Bool,
	hyperMagic:Bool,
	mfuncMagic:Bool,
	assetThumbs:Bool,
	singleClickOpen:Bool,
	showGMLive:PrefGMLive,
	fileChangeAction:PrefFileChangeAction,
	recentProjectCount:Int,
	tabSize:Int,
	tabSpaces:Bool,
	detectTab:Bool,
	eventOrder:Int,
	backupCount:DynamicAccess<Int>,
	tooltipKind:PrefTooltipKind,
	tooltipDelay:Int,
	linterPrefs:parsers.linter.GmlLinterPrefs,
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
