package ace;
import ace.AceWrap;
import gml.GmlAPI;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class AceGmlCompletion implements AceAutoCompleter {
	public static var stdCompleter:AceGmlCompletion;
	public static var gmlCompleter:AceGmlCompletion;
	public static var extCompleter:AceGmlCompletion;
	public static var eventCompleter:AceGmlCompletion;
	public static var localCompleter:AceGmlCompletion;
	public static var globalCompleter:AceGmlCompletion;
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
		//
		var nf = new Dictionary<Bool>();
		nf.set("comment", true);
		nf.set("comment.doc", true);
		nf.set("comment.line", true);
		nf.set("comment.line.doc", true);
		nf.set("string", true);
		nf.set("eventname", true);
		nf.set("macroname", true);
		nf.set("globalfield", true);
		localCompleter = new AceGmlCompletion([], nf, true);
		stdCompleter = new AceGmlCompletion(GmlAPI.stdComp, nf, true);
		extCompleter = new AceGmlCompletion(GmlAPI.extComp, nf, true);
		gmlCompleter = new AceGmlCompletion(GmlAPI.gmlComp, nf, true);
		//
		var ef = new Dictionary<Bool>();
		ef.set("eventname", true);
		eventCompleter = new AceGmlCompletion(gml.GmlEvent.comp, ef, false);
		//
		var globalFilter = new Dictionary<Bool>();
		globalFilter.set("globalfield", true);
		globalCompleter = new AceGmlCompletion(GmlAPI.gmlGlobalFieldComp, globalFilter, false);
		//
		editor.setOptions({
			enableLiveAutocompletion: [
				localCompleter,
				stdCompleter,
				extCompleter,
				gmlCompleter,
				eventCompleter,
				globalCompleter,
			]
		});
	}
}
