package ace.extern;
import ace.extern.AceDocument;
import ace.extern.AcePos;

/**
 * ...
 * @author YellowAfterlife
 */
extern class AceAnchor {
	function new(doc:AceDocument, row:Int, column:Int);
	function detach():Void;
	
	var row:Int;
	var column:Int;
	
	function getDocument():AceDocument;
	function getPosition():AcePos;
	function setPosition(row:Int, column:Int, ?noClip:Bool):Void;
}