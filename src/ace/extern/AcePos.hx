package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract AcePos(AcePosImpl) from AcePosImpl to AcePosImpl {
	public inline function new(column:Int, row:Int) {
		this = { column: column, row: row };
	}
	public inline function toString():String {
		return '[Ln ' + (this.row + 1) + ', col ' + (this.column + 1) + ']';
	}
}
private typedef AcePosImpl = { column: Int, row:Int };
