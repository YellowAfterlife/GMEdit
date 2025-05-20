package electron.extern;

extern class NodeBuffer {
	var length:Int;
	
	function readInt32LE(offset:Int):Int;
	function readDoubleLE(offset:Int):Float;
	
	inline function getString(start:Int, end:Int):String {
		return subarray(start, end).toString();
	}
	
	function subarray(?start:Int, ?end:Int):NodeBuffer;
	
	function toString():String;
}