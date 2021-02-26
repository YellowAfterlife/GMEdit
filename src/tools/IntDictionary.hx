package tools;

/**
 * A pretty simple wrapper for externs
 * @author YellowAfterlife
 */
abstract IntDictionary<T>(Dynamic) from Dynamic {
	
	public inline function new() {
		this = js.lib.Object.create(null);
	}
	
	@:arrayAccess public inline function get(key:Int):T {
		return untyped this[key];
	}
	
	public inline function set(key:Int, val:T):Void {
		untyped this[key] = val;
	}
	
	@:arrayAccess inline function setret(key:Int, val:T):T {
		return untyped this[key] = val;
	}
	
	public inline function exists(k:Int):Bool {
		return Reflect.hasField(this, cast k);
	}
	public inline function forEach(fn:Int->T->Void):Void {
		NativeObject.forField(this, function(s) {
			var i = Std.parseInt(s);
			fn(i, get(i));
		});
	}
}