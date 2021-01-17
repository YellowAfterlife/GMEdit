package tools;
using StringTools;
using tools.NativeString;

/**
 * In a good case scenario, inlines completely.
 * @author YellowAfterlife
 */
class StringReader {
	//
	public var source(default, null):String;
	public var pos:Int;
	public var length(default, null):Int;
	//
	public inline function tell():Int {
		return pos;
	}
	public inline function seek(p:Int):Void {
		pos = p;
	}
	//
	public inline function new(src:String) {
		source = src;
		length = source.length;
		pos = 0;
	}
	public inline function close():Void {
		source = null;
	}
	//
	public inline function read():CharCode {
		return source.fastCodeAt(pos++);
	}
	public inline function peek(offset:Int = 0):CharCode {
		return source.fastCodeAt(offset != 0 ? pos + offset : pos);
	}
	public inline function skipPeek():CharCode {
		return source.fastCodeAt(++pos);
	}
	public inline function skip(num:Int = 1):Void {
		pos += num;
	}
	public inline function get(p:Int):CharCode {
		return source.fastCodeAt(p);
	}
	public inline function substring(start:Int, till:Int):String {
		return source.substring(start, till);
	}
	public inline function substr(start:Int, length:Int):String {
		return source.fastSub(start, length);
	}
}
