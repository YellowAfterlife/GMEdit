package tools;
using StringTools;

/**
 * In a good case scenario, inlines completely.
 * @author YellowAfterlife
 */
class StringReader {
	//
	private var source:String;
	public var pos:Int;
	public var length(default, null):Int;
	//
	public var loop(get, never):Bool;
	private inline function get_loop():Bool {
		return (pos < length);
	}
	//
	public var eof(get, never):Bool;
	private inline function get_eof():Bool {
		return (pos >= length);
	}
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
		return source.substr(start, length);
	}
}
