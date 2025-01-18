package tools;

/**
	Extra utilities for working with arrays.
**/
class ArrayUtils {

	/**
		Return a new, flattened array based on the result of the callback function.
	**/
	public static inline function flatMap<T, R>(
		array:Array<T>,
		callbackFn:T -> Array<R>
	): Array<R> {
		return Reflect.callMethod(array, Reflect.field(array, "flatMap"), [callbackFn]);
	}

}
