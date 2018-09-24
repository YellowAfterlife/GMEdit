package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract AceAutoCompleteItems(Array<AceAutoCompleteItem>)
from Array<AceAutoCompleteItem> to Array<AceAutoCompleteItem> {
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
