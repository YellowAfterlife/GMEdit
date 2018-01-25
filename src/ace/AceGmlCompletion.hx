package ace;
import ace.AceWrap;
import gml.GmlAPI;
import parsers.GmlKeycode;
import parsers.GmlEvent;
import shaders.ShaderAPI;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class AceGmlCompletion implements AceAutoCompleter {
	public static var noItems:AceGmlCompletion_noItems = new AceGmlCompletion_noItems();
	//
	public static var stdCompleter:AceGmlCompletion;
	public static var gmlCompleter:AceGmlCompletion;
	public static var extCompleter:AceGmlCompletion;
	public static var eventCompleter:AceGmlCompletion;
	public static var localCompleter:AceGmlCompletion;
	public static var globalCompleter:AceGmlCompletion;
	public static var keynameCompleter:AceGmlCompletion;
	public static var glslCompleter:AceGmlCompletion;
	public static var hlslCompleter:AceGmlCompletion;
	//
	public var items:AceAutoCompleteItems;
	public var tokenFilter:Dictionary<Bool>;
	public var tokenFilterNot:Bool;
	public var modeFilter:AceSession->Bool;
	public var minLength:Int = 2;
	//
	public function new(
		items:AceAutoCompleteItems, filters:Array<String>, not:Bool,
		modeFilter:AceSession->Bool
	) {
		items.autoSort();
		this.items = items;
		this.tokenFilter = new Dictionary();
		for (ft in filters) this.tokenFilter.set(ft, true);
		this.tokenFilterNot = not;
		this.modeFilter = modeFilter;
	}
	// interface AceAutoCompleter
	public function getCompletions(
		editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb
	):Void {
		if (prefix.length < minLength || !modeFilter(session)) {
			callback(null, noItems);
			return;
		}
		if (editor.completer != null) {
			editor.completer.exactMatch = true;
		}
		var tk = session.getTokenAtPos(pos);
		if (tokenFilter.exists(tk.type) != tokenFilterNot) {
			callback(null, items);
		} else callback(null, noItems);
	}
	public function getDocTooltip(item:AceAutoCompleteItem):String {
		return item.doc;
	}
	//
	public static function init(editor:AceWrap) {
		//
		var gmlModes = new Dictionary();
		gmlModes.set("ace/mode/gml", true);
		gmlModes.set("ace/mode/gml_search", true);
		var gmlf = function(session:AceSession) {
			return gmlModes[session.modeId];
		};
		// tokens to not show normal auto-completion in
		var excl = [
			"comment", "comment.doc", "comment.line", "comment.line.doc",
			"string",
			"scriptname",
			"eventname", "eventkeyname", "eventtext",
			"sectionname",
			"momenttime", "momentname",
			"macroname",
			"globalfield", // global.<text>
		];
		localCompleter = new AceGmlCompletion([], excl, true, gmlf);
		stdCompleter = new AceGmlCompletion(GmlAPI.stdComp, excl, true, gmlf);
		extCompleter = new AceGmlCompletion(GmlAPI.extComp, excl, true, gmlf);
		gmlCompleter = new AceGmlCompletion(GmlAPI.gmlComp, excl, true, gmlf);
		eventCompleter = new AceGmlCompletion(parsers.GmlEvent.comp, ["eventname"], false, gmlf);
		globalCompleter = new AceGmlCompletion(GmlAPI.gmlGlobalFieldComp, ["globalfield"], false, gmlf);
		keynameCompleter = new AceGmlCompletion(GmlKeycode.comp, ["eventkeyname"], false, gmlf);
		//
		glslCompleter = new AceGmlCompletion(ShaderAPI.glslComp, excl, true, function(q) {
			return q.modeId == "ace/mode/shader" && gml.GmlFile.current.kind == GLSL;
		});
		hlslCompleter = new AceGmlCompletion(ShaderAPI.glslComp, excl, true, function(q) {
			return q.modeId == "ace/mode/shader" && gml.GmlFile.current.kind == HLSL;
		});
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
				glslCompleter,
				hlslCompleter,
			]
		});
	}
}

private abstract AceGmlCompletion_noItems(AceAutoCompleteItems) to AceAutoCompleteItems {
	public inline function new() this = [];
}
