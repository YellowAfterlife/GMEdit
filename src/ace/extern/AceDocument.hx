package ace.extern;
import ace.extern.AceAnchor;

/**
 * ...
 * @author YellowAfterlife
 */
extern class AceDocument {
	function getLine(row:Int):String;
	function setValue(s:String):Void;
	function replace(range:AceRange, text:String):Void;
	function remove(range:AceRange):Void;
	function insertMergedLines(pos:AcePos, lines:Array<String>):Void;
	function createAnchor(row:Int, column:Int):AceAnchor;
	
	// non-standard:
	var gmlBookmarks:Array<AceAnchor>;
}
