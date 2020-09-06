package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
extern class AceDelayedCall {
	function delay(?timeout:Int):Void;
	function schedule(?timeout:Int):Void;
	
	function call():Void;
	function cancel():Void;
	inline function isPending():Bool {
		return !!isPendingImpl();
	}
	@:native("isPending") private function isPendingImpl():Dynamic;
}