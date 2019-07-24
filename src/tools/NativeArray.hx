package tools;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class NativeArray {
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
	public static function insertAfter<T>(arr:Array<T>, insertWhat:T, afterWhat:T):Void {
		var i = arr.indexOf(afterWhat);
		if (i >= 0) {
			arr.insert(i + 1, insertWhat);
		} else arr.push(insertWhat);
	}
	public static function insertBefore<T>(arr:Array<T>, insertWhat:T, beforeWhat:T):Void {
		var i = arr.indexOf(beforeWhat);
		if (i >= 0) {
			arr.insert(i, insertWhat);
		} else arr.unshift(insertWhat);
	}
	public static function replaceOne<T>(arr:Array<T>, replaceWhat:T, withWhat:T):Bool {
		var i = arr.indexOf(replaceWhat);
		if (i >= 0) {
			arr[i] = withWhat;
			return true;
		} else return false;
	}
	
	/** Purges all array items for which fn(item) returned false */
	@:extern public static inline function filterSelf<T>(arr:Array<T>, fn:T->Bool):Void {
		var i:Int = 0;
		while (i < arr.length) {
			if (fn(arr[i])) {
				i++;
			} else arr.splice(i, 1);
		}
	}
}
