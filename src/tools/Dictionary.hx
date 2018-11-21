package tools;

/**
 * ...
 * @author YellowAfterlife
 */
#if (js)
@:forward(keys)
abstract Dictionary<T>(Dynamic) from Dynamic {
	public inline function new() {
		this = js.Object.create(null);
	}
	public static function fromKeys<T>(keys:Array<String>, val:T):Dictionary<T> {
		var out = new Dictionary();
		for (key in keys) out.set(key, val);
		return out;
	}
	public static function fromObject<T>(obj:Dynamic):Dictionary<T> {
		var out = new Dictionary<T>();
		NativeObject.forField(obj, function(s) {
			out.set(s, untyped obj[s]);
		});
		return out;
	}
	public inline function destroy():Void { }
	//
	public inline function exists(k:String):Bool {
		return Reflect.hasField(this, k);
	}
	@:arrayAccess public inline function get(k:String):T {
		return untyped this[k];
	}
	public inline function set(k:String, v:T):Void {
		untyped this[k] = v;
	}
	public inline function remove(k:String):Void {
		untyped __js__("delete {0}[{1}]", this, k);
	}
	public inline function keys():Array<String> {
		return Reflect.fields(this);
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
