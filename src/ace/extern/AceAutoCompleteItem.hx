package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
/** (name, meta, ?doc) */
@:forward abstract AceAutoCompleteItem(AceAutoCompleteItemImpl)
from AceAutoCompleteItemImpl to AceAutoCompleteItemImpl {
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
typedef AceAutoCompleteItemImpl = { name:String, value:String, score:Int, meta:String, doc:String };
