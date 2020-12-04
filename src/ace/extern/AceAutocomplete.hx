package ace.extern;
import js.lib.Function;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("AceAutocomplete") extern class AceAutocomplete {
	function new();
	function detach():Void;
	var completions:AceAutocompleteCompletions;
	var exactMatch:Bool;
	var autoInsert:Bool;
	var activated:Bool;
	function showPopup(editor:AceWrap):Void;
	function insertMatch(data:Any, options:Any):Bool;
	var popup:AcePopup;
	/// non-standard
	var shouldSort:Bool;
	var eraseSelfDot:Bool;
	var insertMatch_base:Function;
	var detach_base:Function;
	var isShowPopup:Bool;
}
extern class AceAutocompleteCompletions {
	public var filterText:String;
}