package ace;
import ace.AceGmlTools;
import ace.extern.*;
import ace.extern.AceCommandManager;
import ace.AceWrap;
import ace.AceWrapCompleter;
import ace.AceSnippets;
import file.kind.gml.*;
import file.kind.yy.*;
import file.kind.gmx.*;
import gml.GmlAPI;
import gml.GmlScopes;
import gml.Project;
import gml.file.GmlFile;
import parsers.GmlEvent;
import parsers.GmlKeycode;
import shaders.ShaderAPI;
import tools.Dictionary;
import file.kind.misc.*;
import ui.Preferences;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class AceWrapCommonCompleters {
	public var excludeTokens:Dictionary<Bool> = Dictionary.fromKeys([
		"comment", "comment.doc", "comment.line", "comment.doc.line",
		"string", "string.quasi", "string.importpath", "numeric",
		"scriptname",
		"eventname", "eventkeyname", "eventtext",
		"sectionname", "regionname",
		"momenttime", "momentname",
		"macroname",
		"namespace",
		"globalfield", // global.<text>
		"enumfield", "enumerror",
	], true);
	
	public var gmlModes:Dictionary<Bool> = Dictionary.fromKeys([
		"ace/mode/gml",
		"ace/mode/gml_search",
	], true);
	public function gmlOnly(session:AceSession):Bool {
		return gmlModes[session.modeId];
	}
	
	public var completers:Array<AceAutoCompleter> = [];
	public var stdCompleter:AceWrapCompleter;
	public var gmlCompleter:AceWrapCompleter;
	public var extCompleter:AceWrapCompleter;
	public var eventCompleter:AceWrapCompleter;
	public var localCompleter:AceWrapCompleter;
	public var importCompleter:AceWrapCompleter;
	/** completes from file's imports */
	public var namespaceCompleter:AceWrapCompleter;
	/** completes from global namespaces */
	public var namespaceAltCompleter:AceWrapCompleter;
	public var namespaceTypeCompleter:AceWrapCompleter;
	public var enumTypeCompleter:AceWrapCompleter;
	public var lambdaCompleter:AceWrapCompleter;
	/** completes from file's imports */
	public var localTypeCompleter:AceWrapCompleter;
	/** completes from global namespaces */
	public var localTypeAltCompleter:AceWrapCompleter;
	public var enumCompleter:AceWrapCompleter;
	public var globalCompleter:AceWrapCompleter;
	public var globalFullCompleter:AceWrapCompleter;
	public var instCompleter:AceWrapCompleter;
	public var keynameCompleter:AceWrapCompleter;
	public var glslCompleter:AceWrapCompleter;
	public var hlslCompleter:AceWrapCompleter;
	public var snippetCompleter:AceAutoCompleter;
	public var keywordCompleterStat:AceWrapCompleter;
	public var keywordCompleterExpr:AceWrapCompleter;
	public var keywordCompleterGMS23_function:AceWrapCompleter;
	public var hashtagCompleters:Array<AceWrapCompleter>;
	
	/** These have their items updated by AceStatusBar on context navigation */
	function initLocal() {
		localCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		completers.push(localCompleter);
		
		importCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		completers.push(importCompleter);
		
		lambdaCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		completers.push(lambdaCompleter);
	}
	
	/** The following work on premise that they will execute in a row */
	function initKeywords() {
		var ctxKind:AceGmlContextKind = null;
		keywordCompleterStat = new AceWrapCompleterCustom(GmlAPI.kwCompStat, excludeTokens, true,
		gmlOnly, function(cc, editor, session, pos, prefix, callback) {
			if (!Preferences.current.compKeywords) return false;
			ctxKind = AceGmlTools.getContextKind(session, pos);
			return ctxKind == Statement || ctxKind == AfterExpr;
		});
		completers.push(keywordCompleterStat);
		
		keywordCompleterGMS23_function = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("function", "keyword")
		], excludeTokens, true, gmlOnly, function(cc, editor, session, pos, prefix:String, callback) {
			if (!Preferences.current.compKeywords) return false;
			if (!prefix.startsWith("fu")) return false;
			if (!Project.current.isGMS23) return false;
			switch (ctxKind) {
				case Statement, AfterExpr, Expr: return true;
				default: return false;
			}
		});
		completers.push(keywordCompleterGMS23_function);
	}
	
	function initHashtag() {
		hashtagCompleters = [];
		
		function hashLineStartsWith(session:AceSession, pos:AcePos, prefix:String, start:String):Bool {
			if (pos.column != 1 + prefix.length) return false;
			return session.getLine(pos.row).startsWith(start);
		}
		
		function hashStartsWith(session:AceSession, pos:AcePos, prefix:String, start:String):Bool {
			return session.getLine(pos.row).fastSub(pos.column - 1 - prefix.length, start.length) == start;
		}
		
		for (word in ["region", "endregion"]) {
			var start = "#" + word.charAt(0);
			var htRegion = new AceWrapCompleterCustom([
				new AceAutoCompleteItem(word, "preproc"),
			], excludeTokens, true, gmlOnly, function(cc, ed, ssn, pos, prefix, cb) {
				if (!hashStartsWith(ssn, pos, prefix, start)) return false;
				return Project.current.version.config.indexingMode != GMS1;
			});
			hashtagCompleters.push(htRegion);
		}
		
		var htMacro = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("macro", "preproc"),
		], excludeTokens, true, gmlOnly, function(cc, ed, ssn:AceSession, pos, prefix:String, cb) {
			if (!hashLineStartsWith(ssn, pos, prefix, "#m")) return false;
			var file:GmlFile = ssn.gmlFile;
			return Project.current.version.config.indexingMode != GMS1
				|| file != null && Std.is(file.kind, KGmxMacros);
		});
		hashtagCompleters.push(htMacro);
		
		var htDefine = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("define", "preproc"),
		], excludeTokens, true, gmlOnly, function(cc, ed, ssn:AceSession, pos, prefix:String, cb) {
			if (!hashLineStartsWith(ssn, pos, prefix, "#d")) return false;
			var file:GmlFile = ssn.gmlFile;
			if (file == null) return false;
			var kind = file.kind;
			if (Std.is(kind, KGmlExtension) || Std.is(kind, KGmlMultifile)) {
				return true;
			} else if (Std.is(kind, KGmlScript)) {
				return (cast kind:KGmlScript).isScript
					&& Project.current.version.config.indexingMode != GMS2;
			} else return false;
		});
		hashtagCompleters.push(htDefine);
		
		var htEvent = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("event", "preproc"),
		], excludeTokens, true, gmlOnly, function(cc, ed, ssn:AceSession, pos, prefix:String, cb) {
			if (!hashLineStartsWith(ssn, pos, prefix, "#e")) return false;
			var file:GmlFile = ssn.gmlFile;
			return Std.is(file.kind, KYyEvents) || Std.is(file.kind, KGmxEvents);
		});
		hashtagCompleters.push(htEvent);
		
		for (cc in hashtagCompleters) {
			cc.minLength = 1;
			completers.push(cc);
		}
	}
	
	function initAPI() {
		stdCompleter = new AceWrapCompleter(GmlAPI.stdComp, excludeTokens, true, gmlOnly);
		completers.push(stdCompleter);
		
		extCompleter = new AceWrapCompleter(GmlAPI.extComp, excludeTokens, true, gmlOnly);
		completers.push(extCompleter);
		
		gmlCompleter = new AceWrapCompleter(GmlAPI.gmlComp, excludeTokens, true, gmlOnly);
		completers.push(gmlCompleter);
	}
	
	function initEvents() {
		eventCompleter = new AceWrapCompleter(GmlEvent.comp, ["eventname"], false, gmlOnly);
		eventCompleter.minLength = 0;
		completers.push(eventCompleter);
		
		keynameCompleter = new AceWrapCompleter(GmlKeycode.comp, [
			"eventkeyname",
			"eventsep.punctuation.operator",
		], false, gmlOnly);
		keynameCompleter.minLength = 0;
		completers.push(keynameCompleter);
	}
	
	function initVariables() {
		// only used for SectionStart mode (so that gmv can complete global.my_variable)
		globalFullCompleter = new AceWrapCompleter(GmlAPI.gmlGlobalFullComp, excludeTokens, true, function(q) {
			return gmlModes[q.modeId] && ui.Preferences.current.compMatchMode == SectionStart;
		});
		completers.push(globalFullCompleter);
		
		globalCompleter = new AceWrapCompleter(GmlAPI.gmlGlobalFieldComp, ["globalfield"], false, gmlOnly);
		globalCompleter.minLength = 0;
		globalCompleter.dotKind = DKGlobal;
		completers.push(globalCompleter);
		
		instCompleter = new AceWrapCompleter(GmlAPI.gmlInstFieldComp, excludeTokens, true, gmlOnly);
		completers.push(instCompleter);
	}
	
	function initNamespace() {
		namespaceCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		namespaceCompleter.minLength = 0;
		namespaceCompleter.dotKind = DKNamespace;
		completers.push(namespaceCompleter);
		//
		namespaceAltCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		namespaceAltCompleter.minLength = 0;
		namespaceAltCompleter.dotKind = DKNamespace;
		namespaceAltCompleter.dotKindMeta = true;
		completers.push(namespaceAltCompleter);
		//
		namespaceTypeCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		namespaceTypeCompleter.minLength = 0;
		namespaceTypeCompleter.colKind = CKNamespaces;
		completers.push(namespaceTypeCompleter);
		//
		enumTypeCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		enumTypeCompleter.minLength = 0;
		enumTypeCompleter.colKind = CKEnums;
		completers.push(enumTypeCompleter);
		//
		localTypeCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		localTypeCompleter.minLength = 0;
		localTypeCompleter.dotKind = DKLocalType;
		completers.push(localTypeCompleter);
		//
		localTypeAltCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		localTypeAltCompleter.minLength = 0;
		localTypeAltCompleter.dotKind = DKLocalType;
		localTypeAltCompleter.dotKindMeta = true;
		completers.push(localTypeAltCompleter);
	}
	
	function initEnum() {
		enumCompleter = new AceWrapCompleter([], ["enumfield"], false, gmlOnly);
		enumCompleter.minLength = 0;
		enumCompleter.dotKind = DKEnum;
		completers.push(enumCompleter);
	}
	
	function initShaders() {
		glslCompleter = new AceWrapCompleter(ShaderAPI.glslComp, excludeTokens, true, function(q) {
			return q.modeId == "ace/mode/shader" && q.gmlFile != null && Std.is(q.gmlFile.kind, KGLSL);
		});
		completers.push(glslCompleter);
		
		hlslCompleter = new AceWrapCompleter(ShaderAPI.glslComp, excludeTokens, true, function(q) {
			return q.modeId == "ace/mode/shader" && q.gmlFile != null && Std.is(q.gmlFile.kind, KHLSL);
		});
		completers.push(hlslCompleter);
	}
	
	function initSnippets() {
		var base = AceSnippets.completer;
		snippetCompleter = new AceSnippetCompleterProxy(base, excludeTokens, true, gmlOnly);
		completers.push(snippetCompleter);
	}
	
	public function new() {
		initLocal();
		initKeywords();
		initHashtag();
		initAPI();
		initEvents();
		initVariables();
		initNamespace();
		initEnum();
		initShaders();
		initSnippets();
	}
	
	function openAC(editor:AceWrap) {
		if (editor.completer == null) {
			editor.completer = new AceAutocomplete();
		}
		editor.completer.autoInsert = false;
		editor.completer.showPopup(editor);
	}
	
	/**
	 * Automatically open completion when typing things like "global.|"
	 */
	function onDot(editor:AceWrap) {
		var lead = editor.session.selection.lead;
		var iter = new AceTokenIterator(editor.session, lead.row, lead.column);
		var token = iter.stepBackward();
		if (token == null) return;
		var open = switch (token.type) {
			case "namespace", "enum": true;
			case "local", "sublocal": {
				var session = editor.session;
				var scope = session.gmlScopes.get(lead.row);
				var imp = session.gmlEditor.imports[scope];
				(imp != null ? imp.localTypes[token.value] != null : false);
			};
			case "asset.object": true;
			default: {
				switch (token.value) {
					case "global", "self", "other": true;
					default: false;
				}
			}
		};
		if (open) openAC(editor);
	}
	
	function onColon(editor:AceWrap) {
		var session = editor.session;
		var lead = session.selection.lead;
		var iter = new AceTokenIterator(session, lead.row, lead.column);
		if (AceWrapCompleter.checkColon(iter)) openAC(editor);
	}
	
	/**
	 * Automatically open event name completion when typing `#event ¦`
	 */
	function onSpace(editor:AceWrap) {
		var session = editor.session;
		var lead = session.selection.lead;
		if (!NativeString.startsWith(session.getLine(lead.row), "#event")) return;
		var iter = new AceTokenIterator(editor.session, lead.row, lead.column);
		var token = iter.stepBackward();
		if (token == null) return;
		if (token.type == "preproc.event") openAC(editor);
	}
	function onAfterExec(e:AfterExecArgs) {
		if (e.command.name == "insertstring") {
			switch (e.args) {
				case ".": onDot(e.editor);
				case ":": onColon(e.editor);
				case " ": onSpace(e.editor);
			}
		}
	}
	
	public function bind(editor:AceWrap) {
		editor.gmlCompleters = this;
		editor.setOptions({
			enableLiveAutocompletion: completers,
			enableSnippets: true,
		});
		editor.commands.on("afterExec", onAfterExec);
	}
}
extern class AfterExecArgs {
	var type:String;
	var editor:AceWrap;
	var args:String;
	var command:AceCommand;
	var returnValue:Dynamic;
	function preventDefault():Void;
	function stopPropagation():Void;
}
