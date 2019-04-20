package ace;
import ace.extern.*;
import ace.extern.AceCommandManager;
import ace.AceWrap;
import ace.AceWrapCompleter;
import gml.GmlAPI;
import gml.GmlScopes;
import parsers.GmlEvent;
import parsers.GmlKeycode;
import shaders.ShaderAPI;
import tools.Dictionary;
import file.kind.misc.*;

/**
 * ...
 * @author YellowAfterlife
 */
class AceWrapCommonCompleters {
	public var stdCompleter:AceWrapCompleter;
	public var gmlCompleter:AceWrapCompleter;
	public var extCompleter:AceWrapCompleter;
	public var eventCompleter:AceWrapCompleter;
	public var localCompleter:AceWrapCompleter;
	public var importCompleter:AceWrapCompleter;
	public var namespaceCompleter:AceWrapCompleter;
	public var namespaceTypeCompleter:AceWrapCompleter;
	public var enumTypeCompleter:AceWrapCompleter;
	public var lambdaCompleter:AceWrapCompleter;
	public var localTypeCompleter:AceWrapCompleter;
	public var enumCompleter:AceWrapCompleter;
	public var globalCompleter:AceWrapCompleter;
	public var globalFullCompleter:AceWrapCompleter;
	public var instCompleter:AceWrapCompleter;
	public var keynameCompleter:AceWrapCompleter;
	public var glslCompleter:AceWrapCompleter;
	public var hlslCompleter:AceWrapCompleter;
	public var snippetCompleter:AceAutoCompleter;
	
	public function new() {
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
		stdCompleter = new AceWrapCompleter(GmlAPI.stdComp, excl, true, gmlf);
		extCompleter = new AceWrapCompleter(GmlAPI.extComp, excl, true, gmlf);
		gmlCompleter = new AceWrapCompleter(GmlAPI.gmlComp, excl, true, gmlf);
		//
		eventCompleter = new AceWrapCompleter(parsers.GmlEvent.comp, ["eventname"], false, gmlf);
		keynameCompleter = new AceWrapCompleter(GmlKeycode.comp, ["eventkeyname"], false, gmlf);
		//
		importCompleter = new AceWrapCompleter([], excl, true, gmlf);
		localCompleter = new AceWrapCompleter([], excl, true, gmlf);
		lambdaCompleter = new AceWrapCompleter([], excl, true, gmlf);
		//
		globalFullCompleter = new AceWrapCompleter(GmlAPI.gmlGlobalFullComp, excl, true, function(q) {
			return gmlModes[q.modeId] && ui.Preferences.current.compMatchMode == SectionStart;
		});
		//
		globalCompleter = new AceWrapCompleter(GmlAPI.gmlGlobalFieldComp, ["globalfield"], false, gmlf);
		globalCompleter.minLength = 0;
		globalCompleter.dotKind = DKGlobal;
		//
		instCompleter = new AceWrapCompleter(GmlAPI.gmlInstFieldComp, excl, true, gmlf);
		//
		namespaceCompleter = new AceWrapCompleter([], excl, true, gmlf);
		namespaceCompleter.minLength = 0;
		namespaceCompleter.dotKind = DKNamespace;
		//
		namespaceTypeCompleter = new AceWrapCompleter([], excl, true, gmlf);
		namespaceTypeCompleter.minLength = 0;
		namespaceTypeCompleter.colKind = CKNamespaces;
		//
		enumTypeCompleter = new AceWrapCompleter([], excl, true, gmlf);
		enumTypeCompleter.minLength = 0;
		enumTypeCompleter.colKind = CKEnums;
		//
		localTypeCompleter = new AceWrapCompleter([], excl, true, gmlf);
		localTypeCompleter.minLength = 0;
		localTypeCompleter.dotKind = DKLocalType;
		//
		enumCompleter = new AceWrapCompleter([], ["enumfield"], false, gmlf);
		enumCompleter.minLength = 0;
		enumCompleter.dotKind = DKEnum;
		//
		glslCompleter = new AceWrapCompleter(ShaderAPI.glslComp, excl, true, function(q) {
			return q.modeId == "ace/mode/shader" && q.gmlFile != null && Std.is(q.gmlFile.kind, KGLSL);
		});
		hlslCompleter = new AceWrapCompleter(ShaderAPI.glslComp, excl, true, function(q) {
			return q.modeId == "ace/mode/shader" && q.gmlFile != null && Std.is(q.gmlFile.kind, KHLSL);
		});
		//
		snippetCompleter = AceSnippets.completer;
	}
	public function bind(editor:AceWrap) {
		editor.gmlCompleters = this;
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
				globalFullCompleter,
				globalCompleter,
				instCompleter,
				namespaceCompleter,
				namespaceTypeCompleter,
				enumTypeCompleter,
				localTypeCompleter,
				enumCompleter,
				glslCompleter,
				hlslCompleter,
				snippetCompleter,
			],
			enableSnippets: true,
		});
		inline function openAC() {
			if (editor.completer == null) {
				editor.completer = new AceAutocomplete();
			}
			editor.completer.autoInsert = false;
			editor.completer.showPopup(editor);
		}
		// automatically open completion when typing things like "global.|"
		function onDot(e:AfterExecArgs) {
			var lead = editor.session.selection.lead;
			var iter = new AceTokenIterator(editor.session, lead.row, lead.column);
			var token = iter.stepBackward();
			if (token == null) return;
			var open = switch (token.type) {
				case "namespace", "enum": true;
				case "local": {
					var scope = editor.session.gmlScopes.get(lead.row);
					var imp = editor.session.gmlEditor.imports[scope];
					(imp != null ? imp.localTypes[token.value] != null : false);
				};
				default: token.value == "global";
			};
			if (open) openAC();
		}
		function onColon(e:AfterExecArgs) {
			var lead = editor.session.selection.lead;
			var iter = new AceTokenIterator(editor.session, lead.row, lead.column);
			if (AceWrapCompleter.checkColon(iter)) openAC();
		}
		editor.commands.on("afterExec", function(e:AfterExecArgs) {
			if (e.command.name == "insertstring") {
				switch (e.args) {
					case ".": onDot(e);
					case ":": onColon(e);
				}
			}
		});
	}
}
typedef AfterExecArgs = {
	args:String,
	command:AceCommand,
}
