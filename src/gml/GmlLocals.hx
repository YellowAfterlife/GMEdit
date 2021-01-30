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
	//
	public var name:String;
	public var comp:AceAutoCompleteItems = [];
	public var kind:Dictionary<AceTokenType> = new Dictionary();
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
