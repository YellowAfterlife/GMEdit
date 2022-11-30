package ui.miniweb;
import haxe.Rest;

/**
 * ...
 * @author 
 */
extern class MiniWebRunnerAPI {
	function compile(arr:Array<MiniWebSource>):MiniWebCompileResult;
	function call(name:String, args:Rest<Any>):MiniWebCallResult;
	function stop():Void;
	function hookFunction(name:String, fn:MiniWebHook):MiniWebBase;
	function printAST():String;
	dynamic function onCallError(errorText:String, errorPos:MiniWebPos):Void;
}
typedef MiniWebPos = { name:String, row:Int, col:Int };
typedef MiniWebSource = { name:String, main:String, code:String };
typedef MiniWebCompileResult = { errorText:String, errorPos:MiniWebPos };
typedef MiniWebCallResult = { status:String, result:String, errorPos:MiniWebPos };
typedef MiniWebBase = (self:Any, other:Any, rest:Rest<Any>)->Any;
typedef MiniWebHook = (self:Any, other:Any, args:Array<Any>, orig:MiniWebBase)->Any;
