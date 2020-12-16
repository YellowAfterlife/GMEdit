package tools;
import haxe.iterators.ArrayIterator;
import haxe.iterators.ArrayKeyValueIterator;

/**
 * A paired structure containing an (ordered) list of items
 * and a dictionary to quickly look up these items by a string key
 * @author YellowAfterlife
 */
@:forward abstract ArrayMap<T>(ArrayMapImpl<T>)
	from ArrayMapImpl<T> to ArrayMapImpl<T>
{
	public var length(get, never):Int;
	private inline function get_length():Int {
		return this.array.length;
	}
	
	public inline function new() {
		this = new ArrayMapImpl();
	}
	@:arrayAccess private inline function __get(key:String):Null<T> {
		return this.get(key);
	}
	@:arrayAccess private inline function __set(key:String, val:T):T {
		this.set(key, val);
		return val;
	}
	public inline function iterator():ArrayIterator<T> {
		return this.array.iterator();
	}
	public inline function keyValueIterator():ArrayKeyValueIterator<T> {
		return this.array.keyValueIterator();
	}
	public inline function reverseIterator():ArrayKeyValueReverseIterator<T> {
		return new ArrayKeyValueReverseIterator(this.array);
	}
}
@:native("tools.ArrayMap")
@:keep class ArrayMapImpl<T> {
	public var array:Array<T> = [];
	public var map:Dictionary<T> = new Dictionary();
	public function new() {
		//
	}
	public function clear() {
		array.resize(0);
		map.clear();
	}
	public inline function get(key:String):Null<T> {
		return map[key];
	}
	public inline function exists(key:String):Bool {
		return map.exists(key);
	}
	extern private inline function setImpl(key:String, val:T):Void {
		if (map.exists(key)) {
			var old = map[key];
			array.remove(old);
		}
		map[key] = val;
		array.push(val);
	}
	public function set(key:String, val:T):Void {
		setImpl(key, val);
	}
	extern private inline function removeImpl(key:String):Bool {
		if (map.exists(key)) {
			var val = map[key];
			array.remove(val);
			map.remove(key);
			return true;
		} else return false;
	}
	public function remove(key:String):Bool {
		return removeImpl(key);
	}
	
	/** No type constraint but goes on assumption that T has name:String */
	public function addn(val:T):Void {
		var name:String = (cast val).name;
		if (name == null) {
			Main.console.error("Trying to assign a value into a null-field", this, val);
		} else set(name, val);
	}
	/*public function addNamed<K:{name:String} & T>(val:K) {
		set(val.name, val);
	}*/
	public function addnArray<K:{name:String} & T>(items:Array<K>):Void {
		for (item in items) {
			set(item.name, item);
			//setImpl(item.name, item);
		}
	}
	
	/** Similarly goes on assumption that items have var name:String */
	public function nameSort():Void {
		array.sort(function(a, b) {
			return untyped (cast a).name < (cast b).name ? -1 : 1;
		});
	}
}
class ArrayKeyValueReverseIterator<T> {
	var current:Int;
	var array:Array<T>;

	#if !hl inline #end
	public function new(array:Array<T>) {
		this.array = array;
		this.current = array.length;
	}

	#if !hl inline #end
	public function hasNext():Bool {
		return current > 0;
	}

	#if !hl inline #end
	public function next():{key:Int,value:T} {
		return {value:array[--current], key:current};
	}
}

interface ArrayMapNamed {
	public var name:String;
}