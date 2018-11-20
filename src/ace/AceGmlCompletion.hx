package ace;
import ace.AceWrap;
import ace.extern.*;
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
	public static var lambdaCompleter:AceGmlCompletion;
	public static var localTypeCompleter:AceGmlCompletion;
	public static var enumCompleter:AceGmlCompletion;
	public static var globalCompleter:AceGmlCompletion;
	public static var instCompleter:AceGmlCompletion;
	public static var keynameCompleter:AceGmlCompletion;
	public static var glslCompleter:AceGmlCompletion;
	public static var hlslCompleter:AceGmlCompletion;
	//
	public var items:AceAutoCompleteItems;
	public var tokenFilter:Dictionary<Bool>;
	public var tokenFilterNot:Bool;
	public var tokenFilterComment:Bool;
	public var modeFilter:AceSession->Bool;
	public var minLength:Int = 2;
	//
	public var dotKind = dotKindNone;
	public static inline var dotKindNone = 0;
	public static inline var dotKindGlobal = 1;
	public static inline var dotKindNamespace = 2;
	public static inline var dotKindEnum = 3;
	public static inline var dotKindLocalType = 4;
	//
	public function new(
		items:AceAutoCompleteItems, filters:Array<String>, not:Bool,
		modeFilter:AceSession->Bool
	) {
		items.autoSort();
		this.items = items;
		this.tokenFilter = Dictionary.fromKeys(filters, true);
		this.tokenFilterComment = tokenFilter["comment"];
		this.tokenFilterNot = not;
		this.modeFilter = modeFilter;
	}
	//private static var tkBlank:AceToken = 
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
			editor.completer.exactMatch = ui.Preferences.current.compExactMatch;
		}
		var tk = session.getTokenAtPos(pos);
		if (dotKind != dotKindNone && tk.type == "punctuation.operator" && tk.value.contains(".")) {
			var iter = new AceTokenIterator(session, pos.row, pos.column);
			tk = iter.stepBackward();
			switch (dotKind) {
				case dotKindNamespace: {
					if (tk.type == "namespace") {
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
				};
				case dotKindLocalType: {
					if (tk.type == "local") {
						var scope = gml.GmlScopes.get(pos.row);
						if (scope != null) {
							var imp = gml.GmlImports.currentMap[scope];
							if (imp != null) {
								var t = imp.localTypes[tk.value];
								if (t != null) {
									var ns = imp.namespaces[t];
									if (ns != null) {
										callback(null, ns.comp);
										return;
									} else {
										var en = GmlAPI.gmlEnums[t];
										if (en != null) {
											callback(null, en.fieldComp);
											return;
										}
									}
								}
							}
						}
					}
					proc(false);
				};
				case dotKindGlobal: {
					proc(tk.value == "global");
				};
				case dotKindEnum: {
					if (tk.type == "enum") {
						var name = tk.value;
						//
						var scope = gml.GmlScopes.get(pos.row);
						if (scope != null) {
							var imp = gml.GmlImports.currentMap[scope];
							if (imp != null) {
								var s = imp.longenEnum[name];
								if (s != null) name = s;
							}
						}
						//
						var en = GmlAPI.gmlEnums[name];
						if (en != null) {
							callback(null, en.fieldComp);
							return;
						}
					}
					proc(false);
				};
			}
			return;
		}
		var tkf:Bool = tokenFilter.exists(tk.type);
		if (!tkf && tokenFilterComment && tk.type.startsWith("comment")) tkf = true;
		proc(tkf != tokenFilterNot);
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
			"comment", "comment.doc", "comment.line", "comment.doc.line",
			"string", "string.quasi", "string.importpath",
			"scriptname",
			"eventname", "eventkeyname", "eventtext",
			"sectionname",
			"momenttime", "momentname",
			"macroname",
			"namespace",
			"globalfield", // global.<text>
			"enumfield", "enumerror",
		];
		//
		stdCompleter = new AceGmlCompletion(GmlAPI.stdComp, excl, true, gmlf);
		extCompleter = new AceGmlCompletion(GmlAPI.extComp, excl, true, gmlf);
		gmlCompleter = new AceGmlCompletion(GmlAPI.gmlComp, excl, true, gmlf);
		//
		eventCompleter = new AceGmlCompletion(parsers.GmlEvent.comp, ["eventname"], false, gmlf);
		keynameCompleter = new AceGmlCompletion(GmlKeycode.comp, ["eventkeyname"], false, gmlf);
		//
		importCompleter = new AceGmlCompletion([], excl, true, gmlf);
		localCompleter = new AceGmlCompletion([], excl, true, gmlf);
		lambdaCompleter = new AceGmlCompletion([], excl, true, gmlf);
		//
		globalCompleter = new AceGmlCompletion(GmlAPI.gmlGlobalFieldComp, ["globalfield"], false, gmlf);
		globalCompleter.minLength = 0;
		globalCompleter.dotKind = dotKindGlobal;
		//
		instCompleter = new AceGmlCompletion(GmlAPI.gmlInstFieldComp, excl, true, gmlf);
		//
		namespaceCompleter = new AceGmlCompletion([], excl, true, gmlf);
		namespaceCompleter.minLength = 0;
		namespaceCompleter.dotKind = dotKindNamespace;
		//
		localTypeCompleter = new AceGmlCompletion([], excl, true, gmlf);
		localTypeCompleter.minLength = 0;
		localTypeCompleter.dotKind = dotKindLocalType;
		//
		enumCompleter = new AceGmlCompletion([], ["enumfield"], false, gmlf);
		enumCompleter.minLength = 0;
		enumCompleter.dotKind = dotKindEnum;
		//
		glslCompleter = new AceGmlCompletion(ShaderAPI.glslComp, excl, true, function(q) {
			return q.modeId == "ace/mode/shader" && GmlFile.current.kind == GLSL;
		});
		hlslCompleter = new AceGmlCompletion(ShaderAPI.glslComp, excl, true, function(q) {
			return q.modeId == "ace/mode/shader" && GmlFile.current.kind == HLSL;
		});
		//
		var snippetCompleter:AceGmlCompletion = AceSnippets.init();
		editor.setOptions({
			enableLiveAutocompletion: [
				localCompleter,
				importCompleter,
				lambdaCompleter,
				stdCompleter,
				extCompleter,
				gmlCompleter,
				eventCompleter,
				keynameCompleter,
				globalCompleter,
				instCompleter,
				namespaceCompleter,
				localTypeCompleter,
				enumCompleter,
				glslCompleter,
				hlslCompleter,
				snippetCompleter,
			],
			enableSnippets: true,
		});
		// automatically open completion when typing things like "global.|"
		editor.commands.on("afterExec", function(e:Dynamic) {
			if (e.args != "." || e.command.name != "insertstring") return;
			//if (editor.completer != null && editor.completer.activated) return;
			var lead = editor.session.selection.lead;
			var iter = new AceTokenIterator(editor.session, lead.row, lead.column);
			var token = iter.stepBackward();
			if (token == null) return;
			var open = switch (token.type) {
				case "namespace", "enum": true;
				case "local": {
					var scope = gml.GmlScopes.get(lead.row);
					var imp = gml.GmlImports.currentMap[scope];
					(imp != null ? imp.localTypes[token.value] != null : false);
				};
				default: token.value == "global";
			};
			if (open) {
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
