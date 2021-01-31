package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("AceUndoManager") extern class AceUndoManager {
	public function new():Void;
	public function reset():Void;
	public function isClean():Bool;
	public function markClean():Void;
	public function hasUndo():Bool;
	public function hasRedo():Bool;
	public function getRevision():Int;
}
