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
	static inline function createForPos(session:AceSession, pos:AcePos) {
		return new AceTokenIterator(session, pos.row, pos.column);
	}
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
	
	public static function isEOL(it:AceTokenIterator):Bool {
		return it.__tokenIndex >= it.__rowTokens.length;
	}
	
	public static function canStepBackward(it:AceTokenIterator):Bool {
		return it.__row > 0 || it.__tokenIndex > 0;
	}
	public static function canStepForward(it:AceTokenIterator):Bool {
		return it.__row < it.__session.getLength() || it.__tokenIndex < it.__rowTokens.length - 1;
	}
	
	// like normal stepBackward/Forward, but these cannot result in out-of-bounds position
	public static function stepBackwardSafe(it:AceTokenIterator):AceToken {
		if (inline it.canStepBackward()) {
			return it.stepBackward();
		} else return null;
	}
	public static function stepForwardSafe(it:AceTokenIterator):AceToken {
		if (inline it.canStepForward()) {
			return it.stepForward();
		} else return null;
	}
	
	public static function stepBackwardNonText(it:AceTokenIterator):AceToken {
		var tk:AceToken;
		do {
			tk = it.stepBackwardSafe();
		} while (tk != null && tk.type == "text");
		return tk;
	}
	public static function stepForwardNonText(it:AceTokenIterator):AceToken {
		var tk:AceToken;
		do {
			tk = it.stepForwardSafe();
		} while (tk != null && tk.type == "text");
		return tk;
	}
	
	// todo: make these two better
	public static function peekBackward(it:AceTokenIterator):AceToken {
		var tk = it.stepBackward();
		it.stepForward();
		return tk;
	}
	public static function peekForward(it:AceTokenIterator):AceToken {
		var tk = it.stepBackward();
		it.stepForward();
		return tk;
	}
	
	public static function peekBackwardNonText(it:AceTokenIterator):AceToken {
		var row = it.__row;
		var rowTokens = it.__rowTokens;
		var tokenIndex = it.__tokenIndex;
		var tk = it.stepBackwardNonText();
		it.__row = row;
		it.__rowTokens = rowTokens;
		it.__tokenIndex = tokenIndex;
		return tk;
	}
	public static function peekForwardNonText(it:AceTokenIterator):AceToken {
		var row = it.__row;
		var rowTokens = it.__rowTokens;
		var tokenIndex = it.__tokenIndex;
		var tk = it.stepBackwardNonText();
		it.__row = row;
		it.__rowTokens = rowTokens;
		it.__tokenIndex = tokenIndex;
		return tk;
	}
	
	public static function setTo(it:AceTokenIterator, to:AceTokenIterator):Void {
		it.__session = to.__session;
		it.__row = to.__row;
		it.__rowTokens = to.__rowTokens;
		it.__tokenIndex = to.__tokenIndex;
	}
}