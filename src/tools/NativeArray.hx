package tools;

/**
 * ...
 * @author YellowAfterlife
 */
class NativeArray {
	public static inline function clear<T>(arr:Array<T>):Void {
		untyped arr.length = 0;
	}
	public static inline function clearResize<T>(arr:Array<T>, newSize:Int):Void {
		untyped arr.length = 0;
		untyped arr.length = newSize;
	}
	public static inline function resize<T>(arr:Array<T>, newSize:Int):Void {
		untyped arr.length = newSize;
	}
	public static inline function forEach<T>(arr:Array<T>, fn:T->Void):Void {
		untyped arr.forEach(fn);
	}
}
