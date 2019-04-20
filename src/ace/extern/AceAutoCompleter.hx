package ace.extern;
import ace.AceWrap;

/**
 * ...
 * @author YellowAfterlife
 */
interface AceAutoCompleter {
	function getCompletions(
		editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb
	):Void;
	function getDocTooltip(item:AceAutoCompleteItem):String;
}
