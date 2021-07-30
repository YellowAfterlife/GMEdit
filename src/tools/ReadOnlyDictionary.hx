package tools;

import haxe.iterators.DynamicAccessIterator;
import haxe.iterators.DynamicAccessKeyValueIterator;
import tools.NativeObject;

/**
 * ...
 * @author YellowAfterlife
 */
abstract ReadOnlyDictionary<T>(Dynamic) from Dictionary<T> {
	public function copy():ReadOnlyDictionary<T> {
		var dict = new Dictionary();
		NativeObject.forField(this, function(s) {
			dict[s] = get(s);
		});
		return dict;
	}
	//
	public inline function isEmpty():Bool {
		return !NativeObject.hasFields(this);
	}
	public inline function exists(k:String):Bool {
		return Reflect.hasField(this, k);
	}
	//
	@:arrayAccess public inline function get(k:String):T {
		return untyped this[k];
	}
	public function defget(k:String, def:T):T {
		return exists(k) ? get(k) : def;
	}
	public inline function nc(k:String):T {
		return JsTools.nca(this, untyped this[k]);
	}
	//
	public inline function keys():Array<String> {
		return Reflect.fields(this);
	}
	public function size():Int {
		var n = 0;
		NativeObject.forField(this, function(_) {
			n += 1;
		});
		return n;
	}
	//
	public inline function keyValueIterator():DynamicAccessKeyValueIterator<T> {
		return new DynamicAccessKeyValueIterator(this);
	}
	public inline function forEach(fn:String->T->Void):Void {
		NativeObject.forField(this, function(s) fn(s, get(s)));
	}
}