package ace;
import js.html.Window;
#if !starter
import ace.AceMacro;
import ace.extern.*;
import gml.file.GmlFile;
import haxe.Constraints.Function;
import js.html.Element;
import js.html.SpanElement;
import haxe.extern.EitherType;
import tools.Dictionary;
import ace.extern.*;
import ui.ScrollMode;
using tools.HtmlTools;

/**
 * A big, ugly pile of random handwritten externs for Ace components.
 * @author YellowAfterlife
 */
@:forward @:forwardStatics
abstract AceWrap(AceEditor) from AceEditor to AceEditor {
	static var vimReady:Bool = false;
	public function new(el:EitherType<String, Element>, ?o:AceWrapOptions) {
		if (o == null) o = {};
		//
		if (o.create != null) {
			this = o.create(el);
		} else {
			this = AceEditor.edit(el);
		}
		
		(cast this.container).aceEditor = this;
		var self = this;
		this.on("focus", function() {
			Main.window.setTimeout(function() {
				//Main.console.warn(Date.now().getTime(), "Focus for ", self, self.container);
				for (el in HtmlTools.querySelectorEls(Main.document, "pre.ace_editor")) {
					if (el.classList.contains("ace_focus")) continue;
					for (cursor in el.querySelectorEls(".ace_cursor-layer")) {
						cursor.classList.remove("ace_animate-blinking");
					}
				}
			}, 1);
		});
		
		untyped {
			this.$blockScrolling = Infinity;
			this.getFontFamily = function() return this.getOption("fontFamily");
			this.setFontFamily = function(v) this.setOption("fontFamily", v);
		};
		if (o.statusBar != false) new AceStatusBar().bind(this);
		if (o.completers != false) new AceWrapCommonCompleters().bind(this);
		if (o.linter != false) new ace.gml.AceGmlLinter().bind(this);
		if (o.commands != false) AceCommands.init(this, o.isPrimary);
		if (o.contextMenu != false) new AceCtxMenu().bind(this);
		if (o.inputHelpers != false) ui.KeyboardShortcuts.initEditor(this);
		if (o.tooltips != false) AceTooltips.bind(this);
		if (o.preferences != false) ui.Preferences.bindEditor(this);
		if (o.scrollMode != false) new ScrollMode().bind(this);
		if (o.dispatchEvent != false) plugins.PluginEvents.editorCreated({editor:this, options:o});
		editors.EditKeybindings.initEditor(this);
		
		// I don't know how I'm supposed to track Vim module loading up, so:
		var setKeyboardHandler_base:js.lib.Function = cast this.keyBinding.setKeyboardHandler;
		function setKeyboardHandler_hook(kb:Dynamic) {
			if (Reflect.field(kb, "$id") == "ace/keyboard/vim" && !vimReady) {
				var vim:Dynamic = AceWrap.require("ace/keyboard/vim");
				if (vim != null) {
					vim.Vim.defineEx('write', 'w', function(cm:Dynamic, params) {
						var editor:AceWrap = cm.ace;
						var file = editor.session.gmlFile;
						if (file != null) file.save();
					});
					vimReady = true;
				}
			}
			return setKeyboardHandler_base.apply(AceMacro.jsThis, AceMacro.jsArgs);
		};
		untyped this.keyBinding.setKeyboardHandler = setKeyboardHandler_hook;
	}
	//
	public static inline function loadModule(path:String, fn:Dynamic->Void):Void {
		AceEditor.config.loadModule(path, fn);
	}
	//
	public var session(get, set):AceSession;
	private inline function get_session() return this.getSession();
	private inline function set_session(q:AceSession) {
		this.setSession(q);
		return q;
	}
	//
	public var value(get, set):String;
	private inline function get_value() return this.getValue();
	private inline function set_value(s) {
		this.setValue(s);
		this.selection.clearSelection();
		return s;
	}
	//
	public function resetHintError() {
		var mk = this.errorMarker;
		if (mk != null) {
			session.removeMarker(mk);
			this.errorMarker = null;
		}
	}
	public function setHintText(msg:String) {
		var hint = this.statusHint;
		hint.classList.remove("active");
		hint.textContent = msg;
		hint.onclick = null;
		session.clearAnnotations();
	}
	public static function init() {
		var window:Dynamic = Main.window;
		AceEditor.editWrap = function(q) return new AceWrap(q);
		window.AceEditSession = AceEditor.require("ace/edit_session").EditSession;
		window.AceUndoManager = AceEditor.require("ace/undomanager").UndoManager;
		window.AceUserAgent = AceEditor.require("ace/lib/useragent");
		window.AceHashHandler = AceEditor.require("ace/keyboard/hash_handler").HashHandler;
		window.AceKeys = AceEditor.require("ace/lib/keys");
		window.AceTokenIterator = AceEditor.require("ace/token_iterator").TokenIterator;
		var ns_autocomplete = AceEditor.require("ace/autocomplete");
		window.AceAutocomplete = ns_autocomplete.Autocomplete;
		window.AceFilteredList = ns_autocomplete.FilteredList;
		AceFilteredList.init(window.AceFilteredList.prototype);
		window.AceRange = AceEditor.require("ace/range").Range;
		window.AceTooltip = AceEditor.require("ace/tooltip").Tooltip;
		window.AceOOP = AceEditor.require("ace/lib/oop");
		window.BackgroundTokenizer_cmp = ace.gml.AceGmlState.tokenizerEquals;
	}
}
typedef AceWrapOptions = {
	?create:Element->AceWrap,
	?isPrimary:Bool,
	?statusBar:Bool,
	?completers:Bool,
	?linter:Bool,
	?contextMenu:Bool,
	?commands:Bool,
	?inputHelpers:Bool,
	?tooltips:Bool,
	?preferences:Bool,
	?scrollMode:Bool,
	?dispatchEvent:Bool,
};
@:native("ace")
extern class AceEditor {
	// non-std:
	public var statusHint:SpanElement;
	public var errorMarker:AceMarker;
	public var statusBar:AceStatusBar;
	public var gmlCompleters:AceWrapCommonCompleters;
	public var contextMenu:AceCtxMenu;
	public var tooltipManager:AceTooltips;
	//
	public static dynamic function editWrap(el:EitherType<String, Element>):AceWrap;
	//
	public function getValue():String;
	public function setValue(s:String):Void;
	public function getSession():AceSession;
	public function setSession(q:AceSession):Void;
	public function gotoLine(row:Int, col:Int):Void;
	/** gotoLine with 0-based row */
	public inline function gotoLine0(row:Int, col:Int):Void {
		gotoLine(row + 1, col);
	}
	public inline function gotoPos(pos:AcePos):Void {
		gotoLine(pos.row + 1, pos.column);
	}
	public function scrollToLine(line:Int, ?center:Bool, ?animate:Bool, ?callback:Function):Void;
	public function getCursorPosition():AcePos;
	public function getSelectionRange():{ start:AcePos, end:AcePos };
	public function getSelectedText():String;
	public function insert(text:String, ?pasted:Bool):Void;
	public function execCommand(name:String, ?args:Dynamic):Dynamic;
	//
	public var selection:AceSelection;
	public var keyBinding:AceKeybinding;
	public var commands:AceCommandManager;
	public var completer:AceAutocomplete;
	public var renderer:AceRenderer;
	public var container:Element;
	public function focus():Void;
	//
	public function on(ev:String, fn:Dynamic):Void;
	public function off(ev:String, fn:Dynamic):Void;
	//
	public function getOption(name:String):Dynamic;
	public function setOption(name:String, val:Dynamic):Void;
	public function getOptions():Dynamic;
	public function setOptions(opt:Dynamic):Void;
	// globals:
	public static var config:Dynamic;
	public static function edit(el:EitherType<String, Element>, ?opt:Any):AceEditor;
	public static function require(path:String):Dynamic;
	public static function define(path:String, require:Array<String>, impl:AceImpl):Void;
}
extern class AceKeybinding {
	public function getStatusText(e:AceWrap):String;
	public function setKeyboardHandler(kb:Dynamic):Void;
	public function addKeyboardHandler(kb:Dynamic):Void;
	public function removeKeyboardHandler(kb:Dynamic):Void;
}
extern typedef AceRequire = String->Dynamic;
extern typedef AceExports = Dynamic;
extern typedef AceModule = Dynamic;
extern typedef AceImpl = AceRequire->AceExports->AceModule->Void;
//
#end
