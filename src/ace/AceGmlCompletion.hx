package ace;
import ace.AceWrap;
import gml.GmlAPI;
import gml.file.GmlFile;
import parsers.GmlKeycode;
import parsers.GmlEvent;
import shaders.ShaderAPI;
import tools.Dictionary;
using tools.NativeString;

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
	public static var importCompleter:AceGmlCompletion;
	public static var namespaceCompleter:AceGmlCompletion;
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
	public var dotKind = dotKindNone;
	public static inline var dotKindNone = 0;
	public static inline var dotKindGlobal = 1;
	public static inline var dotKindNamespace = 2;
	//
	public function new(
		items:AceAutoCompleteItems, filters:Array<String>, not:Bool,
		modeFilter:AceSession->Bool
	) {
		items.autoSort();
		this.items = items;
		this.tokenFilter = Dictionary.fromKeys(filters, true);
		this.tokenFilterNot = not;
		this.modeFilter = modeFilter;
	}
	// interface AceAutoCompleter
	public function getCompletions(
		editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb
	):Void {
		inline function proc(show:Bool) {
			callback(null, show ? items : noItems);
		}
		if (prefix.length < minLength || !modeFilter(session)) {
			proc(false);
			return;
		}
		if (editor.completer != null) {
			editor.completer.exactMatch = true;
		}
		var tk = session.getTokenAtPos(pos);
		if (dotKind != dotKindNone && tk.type == "punctuation.operator" && tk.value.contains(".")) {
			var iter = new AceTokenIterator(session, pos.row, pos.column);
			tk = iter.stepBackward();
			switch (dotKind) {
				case dotKindNamespace: {
					if (dotKind == dotKindNamespace) {
						var scope = gml.GmlScopes.get(pos.row);
						if (scope != null) {
							var imp = gml.GmlImports.currentMap[scope];
							if (imp != null) {
								var ns = imp.namespaces[tk.value];
								if (ns != null) {
									callback(null, ns.comp);
									return;
								}
							}
						}
					}
					proc(false);
					return;
				};
				case dotKindGlobal: {
					proc(tk.value == "global");
				};
			}
			return;
		}
		proc(tokenFilter.exists(tk.type) != tokenFilterNot);
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
			"string", "string.quasi", "string.importpath",
			"scriptname",
			"eventname", "eventkeyname", "eventtext",
			"sectionname",
			"momenttime", "momentname",
			"macroname",
			"namespace",
			"globalfield", // global.<text>
		];
		namespaceCompleter = new AceGmlCompletion([], excl, true, gmlf);
		namespaceCompleter.minLength = 0;
		namespaceCompleter.dotKind = dotKindNamespace;
		importCompleter = new AceGmlCompletion([], excl, true, gmlf);
		localCompleter = new AceGmlCompletion([], excl, true, gmlf);
		stdCompleter = new AceGmlCompletion(GmlAPI.stdComp, excl, true, gmlf);
		extCompleter = new AceGmlCompletion(GmlAPI.extComp, excl, true, gmlf);
		gmlCompleter = new AceGmlCompletion(GmlAPI.gmlComp, excl, true, gmlf);
		eventCompleter = new AceGmlCompletion(parsers.GmlEvent.comp, ["eventname"], false, gmlf);
		globalCompleter = new AceGmlCompletion(GmlAPI.gmlGlobalFieldComp, ["globalfield"], false, gmlf);
		globalCompleter.minLength = 0;
		globalCompleter.dotKind = dotKindGlobal;
		keynameCompleter = new AceGmlCompletion(GmlKeycode.comp, ["eventkeyname"], false, gmlf);
		//
		glslCompleter = new AceGmlCompletion(ShaderAPI.glslComp, excl, true, function(q) {
			return q.modeId == "ace/mode/shader" && gml.file.GmlFile.current.kind == GLSL;
		});
		hlslCompleter = new AceGmlCompletion(ShaderAPI.glslComp, excl, true, function(q) {
			return q.modeId == "ace/mode/shader" && gml.file.GmlFile.current.kind == HLSL;
		});
		//
		editor.setOptions({
			enableLiveAutocompletion: [
				localCompleter,
				importCompleter,
				stdCompleter,
				extCompleter,
				gmlCompleter,
				eventCompleter,
				globalCompleter,
				namespaceCompleter,
				keynameCompleter,
				glslCompleter,
				hlslCompleter,
			]
		});
		//
		editor.commands.on("afterExec", function(e:Dynamic) {
			if (e.args != "." || e.command.name != "insertstring") return;
			if (editor.completer != null && editor.completer.activated) return;
			var lead = editor.session.selection.lead;
			var iter = new AceTokenIterator(editor.session, lead.row, lead.column);
			var token = iter.stepBackward();
			if (token == null) return;
			if (token.type == "namespace" || token.value == "global") {
				if (editor.completer == null) {
					editor.completer = new AceAutocomplete();
				}
				editor.completer.autoInsert = false;
				editor.completer.showPopup(editor);
			}
		});
	}
}

private abstract AceGmlCompletion_noItems(AceAutoCompleteItems) to AceAutoCompleteItems {
	public inline function new() this = [];
}
