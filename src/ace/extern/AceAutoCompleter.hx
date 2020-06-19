package ace.extern;
import ace.AceWrap;
import js.lib.RegExp;

/**
 * ...
 * @author YellowAfterlife
 */
interface AceAutoCompleter {
	public var identifierRegexps:Array<RegExp>;
	function getCompletions(
		editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb
	):Void;
	function getDocTooltip(item:AceAutoCompleteItem):String;
}
