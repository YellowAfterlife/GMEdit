package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
extern class AceDocument {
	function setValue(s:String):Void;
	function replace(range:AceRange, text:String):Void;
	function remove(range:AceRange):Void;
	function insertMergedLines(pos:AcePos, lines:Array<String>):Void;
}
