package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract AceRange(AceRangeImpl) from AceRangeImpl to AceRangeImpl {
	public function new(col1:Int, row1:Int, col2:Int, row2:Int):AceRange {
		this = new AceRangeImpl(row1, col1, row2, col2);
	}
	public static function fromPair(start:AcePos, end:AcePos):AceRange {
		return new AceRange(start.column, start.row, end.column, end.row);
	}
	public static function fromPos(pos:AcePos):AceRange {
		return new AceRange(pos.column, pos.row, pos.column, pos.row);
	}
}
@:native("AceRange") private extern class AceRangeImpl {
	public var start:AcePos;
	public var end:AcePos;
	public function new(startRow:Int, startCol:Int, endRow:Int, endCol:Int):Void;
	// todo
}
