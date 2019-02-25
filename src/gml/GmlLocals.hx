package gml;
import ace.AceWrap;
import ace.extern.*;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLocals {
	public static var defaultMap:Dictionary<GmlLocals> = new Dictionary();
	//public static var currentMap:Dictionary<GmlLocals> = defaultMap;
	//
	public var comp:AceAutoCompleteItems = [];
	public var kind:Dictionary<String> = new Dictionary();
	/** T of `var v:T` in type magic */
	public var type:Dictionary<String> = new Dictionary();
	public function add(name:String, lkind:String, ?doc:String) {
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
			type.set(name, locals.type[name]);
		}
	}
	public function new() {
		
	}
}
