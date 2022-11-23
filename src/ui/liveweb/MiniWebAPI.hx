package ui.liveweb;
import haxe.Rest;

/**
 * ...
 * @author 
 */
extern class MiniWebAPI {
	function compile(arr:Array<MiniWebSource>):MiniWebCompileResult;
	function call(name:String, args:Rest<Any>):MiniWebRunResult;
	function stop():Void;
}
typedef MiniWebPos = { name:String, row:Int, col:Int };
typedef MiniWebSource = { name:String, main:String, code:String };
typedef MiniWebCompileResult = { errorText:String, errorPos:MiniWebPos };
typedef MiniWebRunResult = { status:String, errorText:String, errorPos:MiniWebPos };
