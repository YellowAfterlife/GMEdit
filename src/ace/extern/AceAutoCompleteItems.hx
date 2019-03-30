package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract AceAutoCompleteItems(Array<AceAutoCompleteItem>)
from Array<AceAutoCompleteItem> to Array<AceAutoCompleteItem> {
	// { https://github.com/HaxeFoundation/haxe/issues/8072
	public var length(get, never):Int;
	private inline function get_length():Int {
		return this.length;
	}
	@:arrayAccess inline function get(i:Int):AceAutoCompleteItem {
		return this[i];
	}
	//}
	public inline function new() {
		this = [];
	}
	public inline function clear() {
		untyped this.length = 0;
	}
	public inline function autoSort() {
		this.sort(function(a, b) {
			return untyped a.name < b.name ? -1 : 1;
		});
	}
}
