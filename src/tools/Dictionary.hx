package tools;

/**
 * ...
 * @author YellowAfterlife
 */
#if (js)
@:forward(keys)
abstract Dictionary<T>(Dynamic) from Dynamic {
	public inline function new() {
		this = untyped Object.create(null);
	}
	public inline function destroy():Void { }
	public inline function exists(k:String):Bool {
		return get(k) != null;
	}
	@:arrayAccess public inline function get(k:String):T {
		return untyped this[k];
	}
	public inline function set(k:String, v:T):Void {
		untyped this[k] = v;
	}
}
#else
@:forward(exists, set, keys, remove)
abstract Dictionary<T>(Map<String, T>) from Map<String, T> {
	public inline function new() this = new Map();
	public inline function destroy():Void { }
	@:arrayAccess public inline function get(k:String):Null<T> return this.get(k);
}
#end
