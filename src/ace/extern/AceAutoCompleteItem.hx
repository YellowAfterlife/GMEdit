package ace.extern;
using tools.NativeString;

/**
 * A wrapper around Ace's auto-completion objects.
 * @author YellowAfterlife
 */
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
		if (this == null) return null;
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
		if (this == null) return;
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
	/** Name shown in auto-completion menu */
	var name:String;
	
	/** Value to be inserted when the item is chosen */
	var value:String;
	
	/** Ace.js supports ordering items by scores but this goes completely unused in GMEdit. */
	var ?score:Int;
	
	/** Item "kind" that makes for a separate column in auto-completion menu. */
	var meta:String;
	
	/**
	 * Documentation line, shown on the right of auto-complete menu.
	 * 
	 * todo: apparently can also be {?docText, ?docHTML} - can show sprite previews right in AC?
	 * However, handling HTML+text means that changing/concatenating doc is suddenly complicated.
	 */
	var ?doc:String;
	
	/** Mostly used for setting a separate snippet title? */
	var ?caption:String;
	
	/** For snippets, this is the snippet string to insert */
	var ?snippet:String;
	
	/**
	 * Used internally for ordering items in "smart completion" mode.
	 * Items that start with the query string are prioritized.
	 */
	var ?exactMatch:Bool;
	
	/**
	 * Used internally by "smart completion" mode to highlight individual matched letters.
	 * One bit per letter, and if your names are longer than 32 chars, that's on you.
	 */
	var ?matchMask:Int;
};
