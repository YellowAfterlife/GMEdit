package ace;
import ace.AceWrap;
import gml.GmlAPI;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class AceGmlCompletion implements AceAutoCompleter {
	public static var localCompleter:AceGmlCompletion;
	public static var noItems:AceAutoCompleteItems = [];
	//
	public var items:AceAutoCompleteItems;
	public var tokenFilter:Dictionary<Bool>;
	public var tokenFilterNot:Bool;
	//
	public function new(items:AceAutoCompleteItems, filter:Dictionary<Bool>, not:Bool) {
		items.autoSort();
		this.items = items;
		this.tokenFilter = filter;
		this.tokenFilterNot = not;
	}
	// interface AceAutoCompleter
	public function getCompletions(
		editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb
	):Void {
		if (prefix.length < 2) {
			callback(null, []);
			return;
		}
		if (editor.completer != null) {
			editor.completer.exactMatch = true;
		}
		var tk = session.getTokenAtPos(pos);
		if (tokenFilter.exists(tk.type) != tokenFilterNot) {
			callback(null, items);
		} else callback(null, []);
	}
	public function getDocTooltip(item:AceAutoCompleteItem):String {
		return item.doc;
	}
	//
	public static function init(editor:AceWrap) {
		var nf = new Dictionary<Bool>();
		nf.set("comment", true);
		nf.set("comment.doc", true);
		nf.set("string", true);
		nf.set("eventname", true);
		var nn = true;
		//
		var ef = new Dictionary<Bool>();
		ef.set("eventname", true);
		//
		localCompleter = new AceGmlCompletion([], nf, true);
		editor.setOptions({
			enableLiveAutocompletion: [
				localCompleter,
				new AceGmlCompletion(GmlAPI.stdComp, nf, true),
				new AceGmlCompletion(GmlAPI.extComp, nf, true),
				new AceGmlCompletion(GmlAPI.gmlComp, nf, true),
				new AceGmlCompletion(gml.GmlEvent.comp, ef, false),
			]
		});
	}
}
