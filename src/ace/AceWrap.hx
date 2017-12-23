package ace;
//import ast.GmlPos;
import js.html.Element;
import js.html.SpanElement;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward @:forwardStatics
abstract AceWrap(AceEditor) from AceEditor to AceEditor {
	public inline function new(el:EitherType<String, Element>) {
		this = AceEditor.edit(el);
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
	public function init() {
		
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
	public function getCursorPosition():AcePos;
	public function getSelectionRange():{ start:AcePos, end:AcePos };
	public var selection:AceSelection;
	public var keyBinding:{ getStatusText: AceEditor->String };
	public var commands:{ recording:Bool };
	public var completer:{ exactMatch:Bool };
	//
	public function on(ev:String, fn:Dynamic):Void;
	public function setOptions(opt:Dynamic):Void;
	// globals:
	public static function edit(el:EitherType<String, Element>):AceEditor;
	public static function require(path:String):Dynamic;
	public static function define(path:String, require:Array<String>, impl:AceImpl):Void;
}
extern typedef AceRequire = String->Dynamic;
extern typedef AceExports = Dynamic;
extern typedef AceModule = Dynamic;
extern typedef AceImpl = AceRequire->AceExports->AceModule->Void;
extern class AceSelection {
	public function clearSelection():Void;
	public function isEmpty():Bool;
	public var lead:AcePos;
	public var rangeCount:Int;
}
@:native("AceEditSession") extern class AceSession {
	public function new(text:String, mode:Dynamic);
	//
	public function getValue():String;
	public function setValue(v:String):Void;
	//
	public function setAnnotations(arr:Array<AceAnnotation>):Void;
	public function clearAnnotations():Void;
	//
	public function addMarker(range:Dynamic, style:String, kind:String):AceMarker;
	public function removeMarker(mk:AceMarker):Void;
	//
	public function getUndoManager():AceUndoManager;
	public function setUndoManager(m:AceUndoManager):Void;
	//
	public function getLine(row:Int):String;
	public function getTokenAt(row:Int, col:Int):AceToken;
	public inline function getTokenAtPos(pos:AcePos):AceToken {
		return getTokenAt(pos.row, pos.column);
	}
	//
	public var bgTokenizer:Dynamic;
}
@:native("AceUndoManager") extern class AceUndoManager {
	public function new():Void;
	public function isClean():Bool;
	public function markClean():Void;
}
typedef AcePos = { column: Int, row:Int };
typedef AceToken = { type:String, value:String, index:Int, start:Int };
typedef AceAnnotation = { row:Int, column:Int, type:String, text:String }
//
/** (name, meta, ?doc) */
@:forward abstract AceAutoCompleteItem(AceAutoCompleteItemImpl)
from AceAutoCompleteItemImpl to AceAutoCompleteItemImpl {
	public inline function new(name:String, meta:String, ?doc:String) {
		this = { name: name, value: name, score: 0, meta: meta, doc: doc };
	}
}
typedef AceAutoCompleteItemImpl = { name:String, value:String, score:Int, meta:String, doc:String };
//
@:forward abstract AceAutoCompleteItems(Array<AceAutoCompleteItem>)
from Array<AceAutoCompleteItem> to Array<AceAutoCompleteItem> {
	public inline function new() {
		this = [];
	}
	public inline function clear() {
		untyped this.length = 0;
	}
	public inline function autoSort() {
		this.sort(function(a, b) {
			return untyped a.name < b.name ? -1 : 1;
		});
	}
}
//
typedef AceAutoCompleteCb = Dynamic->AceAutoCompleteItems->Void;
interface AceAutoCompleter {
	function getCompletions(
		editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb
	):Void;
	function getDocTooltip(item:AceAutoCompleteItem):String;
}
//
extern class AceMarker { }
extern class AceTokenIterator {
	public function getCurrentToken():AceToken;
	public function stepBackward():Void;
}
