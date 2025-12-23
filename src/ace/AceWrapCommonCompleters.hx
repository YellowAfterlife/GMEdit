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
import tools.JsTools;
import ui.Preferences;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class AceWrapCommonCompleters {
	/** Places where you are generally not supposed to show code completions */
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
	public function shaderOnly(session:AceSession):Bool {
		return session.modeId == "ace/mode/shader" && session.gmlFile != null;
	}
	public function glslOnly(session:AceSession):Bool {
		return shaderOnly(session) && Std.is(session.gmlFile.kind, KGLSL);
	}
	public function hlslOnly(session:AceSession):Bool {
		return shaderOnly(session) && Std.is(session.gmlFile.kind, KHLSL);
	}
	public function codeAny(session:AceSession):Bool {
		return session.gmlFile != null;
	}
	
	public var completers:Array<AceAutoCompleter> = [];
	
	/** Suggests built-ins */
	public var stdCompleter:AceWrapCompleter;
	/** Suggests project-wide items (scripts, assets, macros, etc.) */
	public var gmlCompleter:AceWrapCompleter;
	/** Suggests extension items (functions and macros) */
	public var extCompleter:AceWrapCompleter;
	
	/** Suggests #event names */
	public var eventCompleter:AceWrapCompleter;
	/** Suggests key names for keyboard #events */
	public var keynameCompleter:AceWrapCompleter;
	
	/** Suggests local variables */
	public var localCompleter:AceWrapCompleter;
	/** Suggests #import-ed identifiers */
	public var importCompleter:AceWrapCompleter;
	/** Suggests #lambda function names */
	public var lambdaCompleter:AceWrapCompleter;
	
	/** Suggests local namespaces when typing `var v:` */
	public var namespaceTypeCompleter:AceWrapCompleter;
	/** Suggests global namespaces when typing `var v:` */
	public var namespaceTypeAltCompleter:AceWrapCompleter;
	/** Suggests enums when typing `var v:` */
	public var enumTypeCompleter:AceWrapCompleter;
	
	/** Suggests contextual items from local namespaces */
	public var smartCompleter:AceWrapCompleter;
	/** Suggests contextual items from global namespaces */
	public var smartAltCompleter:AceWrapCompleter;
	
	/** Suggests enum constructs when typing `Enum.` */
	public var enumCompleter:AceWrapCompleter;
	
	/** Suggests global variables when typing `global.` */
	public var globalCompleter:AceWrapCompleter;
	/** Suggests global variables in section-match mode, allowing `Gmv` for `global.my_var` */
	public var globalFullCompleter:AceWrapCompleter;
	
	/** Suggests instance variables that were collected across the project */
	public var instCompleter:AceWrapCompleter;
	
	/** Suggests GLSL-specific completions */
	public var glslCompleter:AceWrapCompleter;
	
	/** Suggests HLSL-specific completions */
	public var hlslCompleter:AceWrapCompleter;
	
	/** Suggests saved Ace snippets */
	public var snippetCompleter:AceAutoCompleter;
	
	/** Suggests statement/expression keywords (`self`, `global`, etc.) */
	public var keywordCompleterExprStat:AceWrapCompleter;
	
	/** Suggests statement-only keywords (`if`, `for`, etc.) */
	public var keywordCompleterStat:AceWrapCompleter;
	
	/** Suggests the 2.3 `function` keyword quite so specifically */
	public var keywordCompleterGMS23_function:AceWrapCompleter;
	
	/** Suggests the 2.3 `constructor` keyword quite so specifically */
	public var keywordCompleterGMS23_constructor:AceWrapCompleter;
	
	/** A mishmash of completers for various `#keyword`s, each with their own conditions */
	public var hashtagCompleters:Array<AceWrapCompleter>;
	
	/** Suggests `@meta`s inside JSDocs */
	public var jsDocCompleter:AceWrapCompleter;
	
	/** Suggests linter flags for `@lint` */
	public var jsDocLinterCompleter:AceWrapCompleter;
	
	public var tupleCompleter:AceWrapCompleter;
	
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
		
		keywordCompleterGMS23_function = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("function", "keyword")
		], excludeTokens, true, gmlOnly, function(cc, editor, session, pos, prefix:String, callback) {
			if (!Preferences.current.compKeywords) return false;
			
			// NB! ctxKind is used in subsequent completers from this block
			ctxKind = AceGmlTools.getContextKind(session, pos);
			
			if (!prefix.startsWith("fu")) return false;
			if (!Project.current.isGMS23) return false;
			return ctxKind == Expr || ctxKind == Statement || ctxKind == AfterExpr;
		});
		completers.push(keywordCompleterGMS23_function);
		
		keywordCompleterGMS23_constructor = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("constructor", "keyword")
		], excludeTokens, true, gmlOnly, function(cc, editor, session, pos:AcePos, prefix:String, callback) {
			if (!Preferences.current.compKeywords) return false;
			
			if (!prefix.startsWith("co")) return false;
			if (!Project.current.isGMS23) return false;
			var line = session.getLine(pos.row);
			var col = pos.column - prefix.length;
			while (--col >= 0) {
				var c = line.fastCodeAt(col);
				if (c == " ".code || c == "\t".code) {
					// OK!
				} else if (c == ")".code) {
					return true;
				} else return false;
			}
			return false;
		});
		completers.push(keywordCompleterGMS23_constructor);
		
		keywordCompleterExprStat = new AceWrapCompleterCustom(GmlAPI.kwCompExprStat,
		excludeTokens, true, gmlOnly, function(cc, editor, session, pos, prefix:String, callback) {
			if (!Preferences.current.compKeywords) return false;
			return ctxKind == Expr || ctxKind == Statement || ctxKind == AfterExpr;
		});
		completers.push(keywordCompleterExprStat);
		
		keywordCompleterStat = new AceWrapCompleterCustom(GmlAPI.kwCompStat,
		excludeTokens, true, gmlOnly, function(cc, editor, session, pos, prefix, callback) {
			if (!Preferences.current.compKeywords) return false;
			return ctxKind == Statement || ctxKind == AfterExpr;
		});
		completers.push(keywordCompleterStat);
		
		var jsk = "keyword";
		var jsDocItems:Array<AceAutoCompleteItem> = [
			new AceAutoCompleteItem("param", jsk, "@param [{Type}] name [description]\nMark a script argument"),
			new AceAutoCompleteItem("returns", jsk, "@returns {Type} [description]\nSets return type"),
			new AceAutoCompleteItem("self", jsk, "@self {Type}\nSets the type of `self`"),
			new AceAutoCompleteItem("is", jsk, "@is {Type}\nHint types of non-local variables"),
			new AceAutoCompleteItem("interface", jsk, "@interface [{Name}]\nMark a script as an interface"),
			new AceAutoCompleteItem("implements", jsk, "@implements [{Name}]\nImplement an interface"),
			new AceAutoCompleteItem("hint", jsk, "(see wiki)\nHint types/variables/methods"),
			new AceAutoCompleteItem("template", jsk, "@template [{Constraint}] Type\nDeclare type parameters"),
			new AceAutoCompleteItem("typedef", jsk, "@typedef {FullType} Alias\nDeclare a shorthand for a type"),
			new AceAutoCompleteItem("init", jsk, "@init\nMarks a non-Create event as a variable/function source"),
			new AceAutoCompleteItem("static", jsk, "@static\nMarks a static variable as intended for access via Constructor.varname"),
		];
		jsDocCompleter = new AceWrapCompleter([], ["comment.meta"], false, gmlOnly);
		for (ac in jsDocItems) jsDocCompleter.items.push(ac); // we don't want items sorted in this one case
		jsDocCompleter.minLength = 0;
		completers.push(jsDocCompleter);
		
		jsDocLinterCompleter = new AceWrapCompleter(
			parsers.linter.misc.GmlLinterJSDocFlag.comp,
			["linterflag", "linterflag.typeerror"],
			false, gmlOnly);
		jsDocLinterCompleter.minLength = 0;
		completers.push(jsDocLinterCompleter);
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
			], excludeTokens, true, codeAny, function(cc, ed, ssn, pos, prefix, cb) {
				if (!hashStartsWith(ssn, pos, prefix, start)) return false;
				return Project.current.version.config.indexingMode != GMS1;
			});
			hashtagCompleters.push(htRegion);
		}
		
		var htMacro = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("macro", "preproc", [
				"#macro name expr",
				"#macro Config:name expr",
			].join("\n")),
		], excludeTokens, true, gmlOnly, function(cc, ed, ssn:AceSession, pos, prefix:String, cb) {
			if (!hashLineStartsWith(ssn, pos, prefix, "#m")) return false;
			var file:GmlFile = ssn.gmlFile;
			return Project.current.version.config.indexingMode != GMS1
				|| file != null && Std.is(file.kind, KGmxMacros);
		});
		hashtagCompleters.push(htMacro);
		
		var htMFunc = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("mfunc", "preproc", [
				"#mfunc name(args) expr",
				'#mfunc name(args) as "type" expr',
				"GMEdit-specific"
			].join("\n")),
		], excludeTokens, true, gmlOnly, function(cc, ed, ssn:AceSession, pos, prefix:String, cb) {
			if (!Preferences.current.mfuncMagic) return false;
			if (!hashLineStartsWith(ssn, pos, prefix, "#m")) return false;
			var file:GmlFile = ssn.gmlFile;
			return Project.current.version.config.indexingMode != GMS1;
		});
		hashtagCompleters.push(htMFunc);
		
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

		var htShaderDefine = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("define", "preproc", [
				"#define name ?expr",
				"#define name(...args) expr"
			].join("\n")),
		], excludeTokens, true, shaderOnly, function(cc, ed, ssn:AceSession, pos, prefix:String, cb) {
			if (!hashLineStartsWith(ssn, pos, prefix, "#d")) return false;
			return true;
		});
		hashtagCompleters.push(htShaderDefine);
		
		var htEvent = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("event", "preproc"),
		], excludeTokens, true, gmlOnly, function(cc, ed, ssn:AceSession, pos, prefix:String, cb) {
			if (!hashLineStartsWith(ssn, pos, prefix, "#e")) return false;
			var file:GmlFile = ssn.gmlFile;
			return Std.is(file.kind, KYyEvents) || Std.is(file.kind, KGmxEvents);
		});
		hashtagCompleters.push(htEvent);

		var htIf = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("if", "preproc", "#if condition"),
		], excludeTokens, true, shaderOnly, function(cc, ed, ssn:AceSession, pos, prefix:String, cb) {
			if (!hashLineStartsWith(ssn, pos, prefix, "#i")) return false;
			return true;
		});
		hashtagCompleters.push(htIf);

		var htElif = new AceWrapCompleterCustom([
			new AceAutoCompleteItem("elif", "preproc", "#elif condition"),
		], excludeTokens, true, shaderOnly, function(cc, ed, ssn:AceSession, pos, prefix:String, cb) {
			if (!hashLineStartsWith(ssn, pos, prefix, "#e")) return false;
			return true;
		});
		hashtagCompleters.push(htElif);

		for (word in ["else", "endif"]) {
			var start = "#" + word.charAt(0);
			var htElse = new AceWrapCompleterCustom([
				new AceAutoCompleteItem(word, "preproc"),
			], excludeTokens, true, shaderOnly, function(cc, ed, ssn, pos, prefix, cb) {
				if (!hashStartsWith(ssn, pos, prefix, start)) return false;
				return true;
			});
			hashtagCompleters.push(htElse);
		}
		
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
		namespaceTypeCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		namespaceTypeCompleter.minLength = 0;
		namespaceTypeCompleter.colKind = CKNamespaces;
		completers.push(namespaceTypeCompleter);
		//
		namespaceTypeAltCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		namespaceTypeAltCompleter.minLength = 0;
		namespaceTypeAltCompleter.colKind = CKNamespaces;
		namespaceTypeAltCompleter.dotKindMeta = true;
		completers.push(namespaceTypeAltCompleter);
		//
		enumTypeCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		enumTypeCompleter.minLength = 0;
		enumTypeCompleter.colKind = CKEnums;
		completers.push(enumTypeCompleter);
		//
		smartCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		smartCompleter.minLength = 0;
		smartCompleter.dotKind = DKSmart;
		completers.push(smartCompleter);
		//
		smartAltCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		smartAltCompleter.minLength = 0;
		smartAltCompleter.dotKind = DKSmart;
		smartAltCompleter.dotKindMeta = true;
		completers.push(smartAltCompleter);
	}
	
	function initEnum() {
		enumCompleter = new AceWrapCompleter([], ["enumfield"], false, gmlOnly);
		enumCompleter.minLength = 0;
		enumCompleter.dotKind = DKEnum;
		completers.push(enumCompleter);
	}
	
	function initShaders() {
		glslCompleter = new AceWrapCompleter(ShaderAPI.glslComp, excludeTokens, true, glslOnly);
		completers.push(glslCompleter);
		
		hlslCompleter = new AceWrapCompleter(ShaderAPI.hlslComp, excludeTokens, true, hlslOnly);
		completers.push(hlslCompleter);
	}
	
	function initSnippets() {
		var base = AceSnippets.completer;
		snippetCompleter = new AceSnippetCompleterProxy(base, excludeTokens, true, gmlOnly);
		completers.push(snippetCompleter);
	}
	
	public function new() {
		completers.push(new AceWrapCompleterCustom([], [], true, (_) -> true,
		function(cc, editor, session, pos, prefix, callback) {
			// resets self-type meta shown in bottom-right of auto-completion list
			var popup = editor.completer.popup;
			if (popup != null) popup.container.removeAttribute("data-self-type");
			return false;
		}));
		//
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
		tupleCompleter = new AceWrapCompleter([], excludeTokens, true, gmlOnly);
		tupleCompleter.minLength = 0;
		tupleCompleter.sqbKind = SKTuple;
		completers.push(tupleCompleter);
	}
	
	function openAC(editor:AceWrap, ?eraseSelfDot:Bool) {
		var ac = editor.completer;
		if (ac == null) {
			editor.completer = ac = new AceAutocomplete();
		}
		//
		ac.eraseSelfDot = eraseSelfDot;
		if (eraseSelfDot && ac.insertMatch_base == null) {
			ac.detach_base = (cast ac).detach;
			function detach_hook() {
				var ac:AceAutocomplete = AceMacro.jsThis;
				if (!ac.isShowPopup) ac.eraseSelfDot = false;
				ac.detach_base.apply(ac, AceMacro.jsArgs);
			}
			(cast ac).detach = detach_hook;
			//
			ac.insertMatch_base = (cast ac).insertMatch;
			function insertMatch_hook(data, options) {
				var ac:AceAutocomplete = AceMacro.jsThis;
				var rangesToRemove:Array<AceRange> = [];
				if (data == null) data = ac.popup.getData(ac.popup.getRow());
				if (data != null && ac.eraseSelfDot) {
					var ranges = editor.selection.getAllRanges();
					var ft = ac.completions.filterText;
					var ftl = ft != null ? ft.length : 0;
					for (range in ranges) {
						var s = range.start;
						var line = editor.session.getLine(s.row);
						s.column -= ftl;
						if (line.charCodeAt(s.column - 1) != ".".code) continue;
						var sub = new AceRange(s.column - 1, s.row, s.column, s.row);
						rangesToRemove.push(sub);
					}
				}
				var result = ac.insertMatch_base.apply(ac, AceMacro.jsArgs);
				for (range in rangesToRemove) editor.session.remove(range);
				return result;
			}
			(cast ac).insertMatch = insertMatch_hook;
		}
		//
		editor.completer.autoInsert = false;
		var wasShowPopup = editor.completer.isShowPopup;
		editor.completer.isShowPopup = true;
		editor.completer.showPopup(editor);
		editor.completer.isShowPopup = wasShowPopup;
	}
	
	/**
	 * Automatically open completion when typing things like "global.|"
	 */
	function onDot(editor:AceWrap, canEraseSelfDot:Bool = true) {
		var session = editor.session;
		if (!gmlOnly(editor.session)) return;
		var lead = session.selection.lead;
		var iter = new AceTokenIterator(session, lead.row, lead.column);
		var token = iter.stepBackward();
		if (token == null) return;
		var eraseSelfDot = false;
		var open = switch (token.type) {
			case "namespace", "enum": true;
			case "local", "sublocal": {
				var scope = session.gmlScopes.get(lead.row);
				var imp = session.gmlEditor.imports[scope];
				(imp != null ? imp.localTypes[token.value] != null : false);
			};
			case "asset.object": true;
			case "punctuation.operator": eraseSelfDot = token.value != ".";
			case "set.operator", "text": eraseSelfDot = true;
			default: {
				switch (token.value) {
					case "global", "self", "other": true;
					case "}", "]", ")": true;
					case "{", "[", "(": eraseSelfDot = true;
					default: token.isIdent();
				}
			}
		};
		if (!open && iter.getCurrentTokenRow() != lead.row) {
			open = true;
			eraseSelfDot = true;
		}
		if (open) openAC(editor, canEraseSelfDot && eraseSelfDot);
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
		
		var iter = new AceTokenIterator(editor.session, lead.row, lead.column);
		var token = iter.stepBackward();
		if (token == null) return;
		
		switch (token.type) {
			case "preproc.event" if (NativeString.startsWith(session.getLine(lead.row), "#event")):
				openAC(editor);
			case "comment.meta" if (token.value == "@lint"):
				openAC(editor);
		}
	}
	
	function onAtSign(editor:AceWrap) {
		var session = editor.session;
		var lead = session.selection.lead;
		var token = session.getTokenAtPos(lead);
		if (token == null) return;
		if (token.type == "comment.meta") openAC(editor);
	}
	function onAfterExec(e:AfterExecArgs) {
		if (e.command.name == "insertstring") {
			var c = e.editor.completer;
			switch (e.args) {
				case ".": onDot(e.editor);
				case "[": onDot(e.editor, false);
				case ":": onColon(e.editor);
				case " ": onSpace(e.editor);
				case "@": onAtSign(e.editor);
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
