package ace;
import ace.extern.*;
import gml.file.GmlFile;
import js.html.Element;
import js.html.SpanElement;
import haxe.extern.EitherType;
import tools.Dictionary;
import ace.extern.*;

/**
 * A big, ugly pile of random handwritten externs for Ace components.
 * @author YellowAfterlife
 */
@:forward @:forwardStatics
abstract AceWrap(AceEditor) from AceEditor to AceEditor {
	public function new(el:EitherType<String, Element>) {
		this = AceEditor.edit(el);
		untyped {
			this.getFontFamily = function() return this.getOption("fontFamily");
			this.setFontFamily = function(v) this.setOption("fontFamily", v);
		};
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
		window.AceEditSession = AceWrap.require("ace/edit_session").EditSession;
		window.AceUndoManager = AceWrap.require("ace/undomanager").UndoManager;
		window.AceTokenIterator = AceWrap.require("ace/token_iterator").TokenIterator;
		window.AceAutocomplete = AceWrap.require("ace/autocomplete").Autocomplete;
		window.AceRange = AceWrap.require("ace/range").Range;
		window.AceTooltip = AceWrap.require("ace/tooltip").Tooltip;
		window.aceEditor = Main.aceEditor;
	}
	/*public function setHintError(msg:String, pos:GmlPos) {
		var Range = untyped ace.require("ace/range").Range;
		var row = pos.row - 1;
		var col = pos.col - 1;
		var range = SfTools.raw("new {0}({1}, {2}, {3}, {4})", Range, row, col, row, col + 1);
		//
		var hint = this.statusHint;
		hint.classList.add("active");
		hint.textContent = msg;
		hint.onclick = function(_) {
			this.gotoLine(row + 1, col);
		};
		//
		var session = this.getSession();
		this.errorMarker = session.addMarker(range, "ace_error-line", "fullLine");
		session.setAnnotations([{
			row: row, column: col, type: "error", text: msg
		}]);
	}*/
}
@:native("ace")
extern class AceEditor {
	// non-std:
	public var statusHint:SpanElement;
	public var errorMarker:AceMarker;
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
	public var renderer:Dynamic;
	public var container:Element;
	public function focus():Void;
	//
	public function on(ev:String, fn:Dynamic):Void;
	//
	public function getOption(name:String):Dynamic;
	public function setOption(name:String, val:Dynamic):Void;
	public function getOptions():Dynamic;
	public function setOptions(opt:Dynamic):Void;
	// globals:
	public static var config:Dynamic;
	public static function edit(el:EitherType<String, Element>):AceEditor;
	public static function require(path:String):Dynamic;
	public static function define(path:String, require:Array<String>, impl:AceImpl):Void;
}
extern class AceKeybinding {
	public function getStatusText(e:AceWrap):String;
	public function addKeyboardHandler(kb:Dynamic):Void;
	public function removeKeyboardHandler(kb:Dynamic):Void;
}
extern typedef AceRequire = String->Dynamic;
extern typedef AceExports = Dynamic;
extern typedef AceModule = Dynamic;
extern typedef AceImpl = AceRequire->AceExports->AceModule->Void;
//
@:native("AceAutocomplete") extern class AceAutocomplete {
	function new();
	var exactMatch:Bool;
	var autoInsert:Bool;
	var activated:Bool;
	function showPopup(editor:AceWrap):Void;
}
typedef AceAutoCompleteCb = Dynamic->AceAutoCompleteItems->Void;
interface AceAutoCompleter {
	function getCompletions(
		editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb
	):Void;
	function getDocTooltip(item:AceAutoCompleteItem):String;
}
//
