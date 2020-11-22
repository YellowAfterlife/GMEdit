package tools;

import haxe.iterators.DynamicAccessIterator;
import haxe.iterators.DynamicAccessKeyValueIterator;
import tools.NativeObject;

/**
 * This is _almost_ like haxe.DynamicAccess, but with some JS-specific tricks.
 * @author YellowAfterlife
 */
#if (js)
@:forward(keys)
abstract Dictionary<T>(Dynamic) from Dynamic {
	public inline function new() {
		this = js.lib.Object.create(null);
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
	public inline function isEmpty():Bool {
		return !NativeObject.hasFields(this);
	}
	public inline function exists(k:String):Bool {
		return Reflect.hasField(this, k);
	}
	public function move(k1:String, k2:String):Bool {
		if (exists(k2)) return false;
		if (exists(k1)) {
			var val = get(k1);
			remove(k1);
			set(k2, val);
			return true;
		} else return false;
	}
	//
	@:arrayAccess public inline function get(k:String):T {
		return untyped this[k];
	}
	public function defget(k:String, def:T):T {
		return exists(k) ? get(k) : def;
	}
	//
	public inline function set(k:String, v:T):Void {
		untyped this[k] = v;
	}
	@:arrayAccess public inline function setret(k:String, v:T):T {
		return untyped this[k] = v;
	}
	//
	public inline function remove(k:String):Void {
		js.Syntax.code("delete {0}[{1}]", this, k);
	}
	public inline function keys():Array<String> {
		return Reflect.fields(this);
	}
	//
	public inline function keyValueIterator():DynamicAccessKeyValueIterator<T> {
		return new DynamicAccessKeyValueIterator(this);
	}
	public inline function forEach(fn:String->T->Void):Void {
		NativeObject.forField(this, function(s) fn(s, get(s)));
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
