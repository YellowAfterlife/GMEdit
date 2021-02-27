package ace.extern;
using tools.NativeString;

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
	/** ("type") for doc="from X\ntype Y" returns "Y" */
	public function getDocTag(key:String):String {
		var doc = this.doc;
		if (doc == null) return null;
		key += " ";
		var pos:Int;
		if (doc.startsWith(key)) {
			pos = key.length;
		} else {
			pos = doc.indexOf("\n" + key);
			if (pos < 0) return null;
			pos += key.length + 1;
		}
		var end = doc.indexOf("\n", pos);
		return end >= 0 ? doc.substring(pos, end) : doc.substring(pos);
	}
	/**
	 * Patches an existing doc line with a key-prefix or adds a new one to the end.
	 * Obviously this can backfire if there is user documentation line starting with same
	 * prefix but what to do.
	 */
	public function setDocTag(key:String, val:String):Void {
		var doc = this.doc;
		if (doc == null) {
			this.doc = key + " " + val;
			return;
		}
		key += " ";
		var pos:Int;
		if (doc.startsWith(key)) {
			pos = key.length;
		} else {
			pos = doc.indexOf("\n" + key);
			if (pos < 0) {
				this.doc += "\n" + key + val;
				return;
			} else pos += key.length + 1;
		}
		var end = doc.indexOf("\n", pos);
		if (end >= 0) {
			this.doc = doc.substring(0, pos) + val + doc.substring(end);
		} else this.doc = doc.substring(0, pos) + val;
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
