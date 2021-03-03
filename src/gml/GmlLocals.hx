package gml;
import ace.AceWrap;
import ace.extern.*;
import tools.Dictionary;

/**
 * Represents local variables specific to a scope
 * @author YellowAfterlife
 */
class GmlLocals {
	public static var defaultMap:Dictionary<GmlLocals> = new Dictionary();
	//
	public var name:String;
	public var comp:AceAutoCompleteItems = [];
	
	/**
	 * Generally token types are "local" and "sublocal",
	 * but can technically be also used for little hacks.
	 */
	public var kind:Dictionary<AceTokenType> = new Dictionary();
	
	/**
	 * Indicates that this local scope contains a with-block
	 * Implications: we can no longer "just" assume that `ident` is self-access
	 */
	public var hasWith:Bool = false;
	
	public function add(name:String, lkind:AceTokenType, ?doc:String) {
		if (kind[name] == null) {
			kind.set(name, lkind);
			comp.push(new AceAutoCompleteItem(name, lkind, doc));
		}
	}
	public function addLocals(locals:GmlLocals) {
		for (item in locals.comp) {
			var name = item.name;
			if (kind.exists(name)) continue;
			comp.push(item);
			kind.set(name, locals.kind[name]);
		}
	}
	public function new(name:String = "") {
		this.name = name;
	}
}
