package ace.extern;
import ace.extern.AceToken;

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
	public static function fromPosLen(pos:AcePos, len:Int):AceRange {
		return new AceRange(pos.column, pos.row, pos.column + len, pos.row);
	}
	public static function fromTokenPos(tk:AceToken, pos:AcePos):AceRange {
		return new AceRange(pos.column, pos.row, pos.column + tk.value.length, pos.row);
	}
}
@:native("AceRange") private extern class AceRangeImpl {
	var start:AcePos;
	var end:AcePos;
	function new(startRow:Int, startCol:Int, endRow:Int, endCol:Int):Void;
	function extend(row:Int, col:Int):AceRange;
	function isEmpty():Bool;
	function isMultiLine():Bool;
	function clipRows(firstRow:Int, lastRow:Int):AceRange;
	function toScreenRange(session:AceSession):AceRange;
}
