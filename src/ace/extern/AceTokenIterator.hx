package ace.extern;
import ace.extern.AceSession;
import ace.extern.AceToken;
import haxe.DynamicAccess;

/**
 * ...
 * @author YellowAfterlife
 */
@:using(ace.extern.AceTokenIterator.AceTokenIteratorTools)
@:native("AceTokenIterator") extern class AceTokenIterator {
	function new(session:AceSession, row:Int, col:Int);
	function getCurrentToken():AceToken;
	function getCurrentTokenRange():AceRange;
	function getCurrentTokenPosition():AcePos;
	function stepBackward():AceToken;
	function stepForward():AceToken;
	function getCurrentTokenRow():Int;
	function getCurrentTokenColumn():Int;
	// private:
	@:native("$session") var __session:AceSession;
	@:native("$row") var __row:Int;
	@:native("$rowTokens") var __rowTokens:Array<AceToken>;
	@:native("$tokenIndex") var __tokenIndex:Int;
}
class AceTokenIteratorTools {
	public static function copy(it:AceTokenIterator):AceTokenIterator {
		var ci = new AceTokenIterator(it.__session, it.__row, 0);
		ci.__tokenIndex = it.__tokenIndex;
		return ci;
	}
	public static function stepBackwardNonText(it:AceTokenIterator):AceToken {
		var tk:AceToken;
		do {
			tk = it.stepBackward();
		} while (tk != null && tk.type == "text");
		return tk;
	}
	public static function stepForwardNonText(it:AceTokenIterator):AceToken {
		var tk:AceToken;
		do {
			tk = it.stepForward();
		} while (tk != null && tk.type == "text");
		return tk;
	}
}