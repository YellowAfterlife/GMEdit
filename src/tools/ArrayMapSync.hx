package tools;
import haxe.iterators.ArrayKeyValueIterator;
import tools.ArrayMap;

/**
 * Like ArrayMap, but has a "last change ID" field that is incremented on change
 * @author YellowAfterlife
 */
@:forward abstract ArrayMapSync<T>(ArrayMapSyncImpl<T>)
	from ArrayMapSyncImpl<T> to ArrayMapSyncImpl<T> to ArrayMapImpl<T> to ArrayMap<T>
{
	public var length(get, never):Int;
	private inline function get_length():Int {
		return this.array.length;
	}
	
	public inline function new() {
		this = new ArrayMapSyncImpl();
	}
	@:arrayAccess private inline function __get(key:String):Null<T> {
		return this.get(key);
	}
	@:arrayAccess private inline function __set(key:String, val:T):T {
		this.set(key, val);
		return val;
	}
	public inline function iterator():Iterator<T> {
		return this.array.iterator();
	}
	public inline function keyValueIterator():ArrayKeyValueIterator<T> {
		return this.array.keyValueIterator();
	}
	public inline function reverseIterator():ArrayKeyValueReverseIterator<T> {
		return new ArrayKeyValueReverseIterator(this.array);
	}
}

@:native("tools.ArrayMapSync")
@:keep class ArrayMapSyncImpl<T> extends ArrayMapImpl<T> {
	/**
	 * Incremented every time a change is made to the structure.
	 * The ID is unique between all of the structure instances.
	 */
	public var changeID:Int = 0;
	private static var __changeID:Int = 0;
	private inline function incChangeID():Void {
		changeID = ++__changeID;
	}
	
	public function new() {
		super();
		incChangeID();
	}
	
	override public function clear() {
		super.clear();
		incChangeID();
	}
	
	override public function set(key:String, val:T):Void {
		setImpl(key, val);
		incChangeID();
	}
	override public function remove(key:String):Bool {
		if (removeImpl(key)) {
			incChangeID();
			return true;
		} else return false;
	}
	/*override public function addnArray<K:{name:String} & T>(items:Array<K>):Void {
		for (item in items) setImpl(item.name, item);
		incChangeID();
	}*/
}
