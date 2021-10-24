package tools;

import js.Syntax;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class NativeArray {
	public static inline function create<T>(size:Int):Array<T> {
		return js.Syntax.code("new Array")(size);
	}

	/**Create a new array from a given content*/
	public static inline function from<T>(content: Dynamic):Array<T> {
		return Syntax.code("Array.from")(content);
	}
	
	/** Concatenate two arrays while allowing either to be null */
	public static function nzcct<T>(a:Array<T>, b:Array<T>, ?copy:Bool):Array<T> {
		if (a != null) {
			if (b != null) {
				return a.concat(b);
			} else return copy ? a.copy() : a;
		} else {
			if (b != null) {
				return copy ? b.copy() : b;
			} else return null;
		}
	}
	
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
	
	/** ([0,1], [2,3,4]) ~> ([2,3,4], [2,3,4]) (shallow copy) */
	public static function setTo<T>(arr:Array<T>, to:Array<T>):Void {
		var n = to.length;
		resize(arr, n);
		var i = 0;
		while (i < n) {
			arr[i] = to[i];
			i++;
		}
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
	extern public static inline function filterSelf<T>(arr:Array<T>, fn:T->Bool):Void {
		var i:Int = 0;
		while (i < arr.length) {
			if (fn(arr[i])) {
				i++;
			} else arr.splice(i, 1);
		}
	}
	
	public static function findFirst<T>(arr:Array<T>, fn:T->Bool):Null<T> {
		var result:Null<T> = null;
		for (v in arr) if (fn(v)) { result = v; break; }
		return result;
	}
}
