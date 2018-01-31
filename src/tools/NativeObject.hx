package tools;

/**
 * Like Reflect, but rawer
 * @author YellowAfterlife
 */
class NativeObject {
	public static inline function removeField(q:Dynamic, fd:String):Void {
		untyped __js__("delete {0}[{1}]", q, fd);
	}
	public static inline function forField(q:Dynamic, fn:String->Void):Void {
		var fd:String = null;
		var has:js.Function = untyped js.Object.prototype.hasOwnProperty;
		untyped __js__("for ({0} in {1}) {2}", fd, q, {
			if (has.call(q, fd)) fn(fd);
		});
	}
}
