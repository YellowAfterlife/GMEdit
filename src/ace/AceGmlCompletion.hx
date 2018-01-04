package ace;
import ace.AceWrap;
import gml.GmlAPI;
import gml.GmlKeycode;
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
	public static var keynameCompleter:AceGmlCompletion;
	public static var noItems:AceAutoCompleteItems = [];
	//
	public var items:AceAutoCompleteItems;
	public var tokenFilter:Dictionary<Bool>;
	public var tokenFilterNot:Bool;
	//
	public function new(items:AceAutoCompleteItems, filters:Array<String>, not:Bool) {
		items.autoSort();
		this.items = items;
		this.tokenFilter = new Dictionary();
		for (ft in filters) this.tokenFilter.set(ft, true);
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
		// tokens to not show normal auto-completion in
		var excl = [
			"comment", "comment.doc", "comment.line", "comment.line.doc",
			"string",
			"scriptname",
			"eventname", "eventkeyname",
			"sectionname",
			"momenttime", "momentname",
			"macroname",
			"globalfield", // global.<text>
		];
		localCompleter = new AceGmlCompletion([], excl, true);
		stdCompleter = new AceGmlCompletion(GmlAPI.stdComp, excl, true);
		extCompleter = new AceGmlCompletion(GmlAPI.extComp, excl, true);
		gmlCompleter = new AceGmlCompletion(GmlAPI.gmlComp, excl, true);
		eventCompleter = new AceGmlCompletion(gml.GmlEvent.comp, ["eventname"], false);
		globalCompleter = new AceGmlCompletion(GmlAPI.gmlGlobalFieldComp, ["globalfield"], false);
		keynameCompleter = new AceGmlCompletion(GmlKeycode.comp, ["eventkeyname"], false);
		//
		editor.setOptions({
			enableLiveAutocompletion: [
				localCompleter,
				stdCompleter,
				extCompleter,
				gmlCompleter,
				eventCompleter,
				globalCompleter,
				keynameCompleter,
			]
		});
	}
}
