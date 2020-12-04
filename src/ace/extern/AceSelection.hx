package ace.extern;
import ace.extern.AceRange;

/**
 * ...
 * @author YellowAfterlife
 */
extern class AceSelection {
	public function clearSelection():Void;
	public function selectWord():Void;
	public function selectTo(row:Int, col:Int):Void;
	public function moveTo(row:Int, col:Int):Void;
	public function isEmpty():Bool;
	public var anchor:AcePos;
	public var lead:AcePos;
	public var rangeCount:Int;
	public function getAllRanges():Array<AceRange>;
	public function toJSON():Dynamic;
	public function fromJSON(q:Dynamic):Void;
}
