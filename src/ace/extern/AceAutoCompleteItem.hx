package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
/** (name, meta, ?doc) */
@:forward abstract AceAutoCompleteItem(AceAutoCompleteItemImpl)
from AceAutoCompleteItemImpl to AceAutoCompleteItemImpl {
	public var rawScore(get, set):Int;
	private inline function get_rawScore():Int {
		return Reflect.field(this, "$score");
	}
	private inline function set_rawScore(v:Int):Int {
		Reflect.setField(this, "$score", v);
		return v;
	}
	public inline function new(name:String, meta:String, ?doc:String) {
		this = { name: name, value: name, score: 0, meta: meta, doc: doc };
	}
	public inline function makeAlias(alias:String) {
		return new AceAutoCompleteItem(alias, this.meta, this.doc);
	}
	public function setTo(c:AceAutoCompleteItem) {
		this.doc = c.doc;
		this.name = c.name;
		this.meta = c.meta;
		this.value = c.value;
		this.score = c.score;
	}
}
typedef AceAutoCompleteItemImpl = {
	var name:String;
	var value:String;
	var score:Int;
	var meta:String;
	var doc:String;
	@:optional var caption:String;
	@:optional var snippet:String;
	@:optional var exactMatch:Bool;
	/** Used internally by "smart completion" mode */
	@:optional var matchMask:Int;
};
