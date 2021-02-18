package tools;
using StringTools;
using tools.NativeString;

/**
 * In a good case scenario, inlines completely.
 * @author YellowAfterlife
 */
@:keep class StringReader {
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
	public inline function readChar():String {
		return source.charAt(pos++);
	}
	public function readChars(count:Int):String {
		var s = source.substr(pos, count);
		pos += count;
		return s;
	}
	
	public inline function peek(offset:Int = 0):CharCode {
		return source.fastCodeAt(pos + offset);
	}
	public inline function peekstr(count:Int, offset:Int = 0):String {
		return source.fastSub(pos + offset, count);
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
	public inline function charAt(p:Int):String {
		return source.charAt(p);
	}
	
	public inline function substring(start:Int, till:Int):String {
		return source.substring(start, till);
	}
	public inline function substr(start:Int, length:Int):String {
		return source.fastSub(start, length);
	}
	public function getWatch(n:Int) {
		var bn = pos < n ? pos : n;
		return source.fastSub(pos - bn, bn) + "¦" + source.fastSub(pos, n);
	}
}
