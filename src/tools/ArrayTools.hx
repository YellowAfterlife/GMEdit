package tools;

/**
	Extra utilities for working with arrays.
**/
class ArrayTools {

	/**
		Return a new, flattened array based on the result of the callback function.
	**/
	public static inline function flatMap<T, R>(
		array:Array<T>,
		callbackFn:T -> Array<R>
	): Array<R> return (cast array).flatMap(callbackFn);

}
