package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("AceAutocomplete") extern class AceAutocomplete {
	function new();
	var exactMatch:Bool;
	var autoInsert:Bool;
	var activated:Bool;
	/// non-standard
	var shouldSort:Bool;
	function showPopup(editor:AceWrap):Void;
}
