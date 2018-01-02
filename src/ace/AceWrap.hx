package ace;
import js.html.Element;
import js.html.SpanElement;
import haxe.extern.EitherType;
import tools.Dictionary;

/**
 * A big, ugly pile of random handwritten externs for Ace components.
 * @author YellowAfterlife
 */
@:forward @:forwardStatics
abstract AceWrap(AceEditor) from AceEditor to AceEditor {
	public inline function new(el:EitherType<String, Element>) {
		this = AceEditor.edit(el);
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
	public var selection:AceSelection;
	public var keyBinding:{ getStatusText: AceEditor->String };
	public var commands:AceCommandManager;
	public var completer:{ exactMatch:Bool, showPopup:AceWrap->Void };
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
extern class AceCommandManager {
	public var recording:Bool;
	public var commands:Dictionary<Dynamic>;
	public var platform:String;
	public function addCommand(cmd:AceCommand):Void;
	public function removeCommand(cmd:EitherType<AceCommand, String>):Void;
	public function bindKey(
		key:AceCommandKey, cmd:EitherType<String, AceWrap->Void>, ?pos:Dynamic
	):Void;
	public function execCommand(cmd:String):Void;
}
extern typedef AceCommand = {
	bindKey:AceCommandKey,
	exec:AceWrap->Void,
	name:String,
	?readOnly: Bool,
	?scrollIntoView:String,
	?multiSelectAction:String,
}
extern typedef AceCommandKey = EitherType<String, { win:String, mac:String }>;
extern typedef AceRequire = String->Dynamic;
extern typedef AceExports = Dynamic;
extern typedef AceModule = Dynamic;
extern typedef AceImpl = AceRequire->AceExports->AceModule->Void;
extern class AceSelection {
	public function clearSelection():Void;
	public function selectWord():Void;
	public function isEmpty():Bool;
	public var lead:AcePos;
	public var rangeCount:Int;
	public function toJSON():Dynamic;
	public function fromJSON(q:Dynamic):Void;
}
@:native("AceEditSession") extern class AceSession {
	public function new(text:String, mode:Dynamic);
	//
	/** Returns the total number of lines */
	public function getLength():Int;
	//
	public function getScrollLeft():Float;
	public function setScrollLeft(left:Float):Void;
	public function getScrollTop():Float;
	public function setScrollTop(top:Float):Void;
	//
	public var foldWidgets:Array<String>;
	public function getFoldWidget(row:Int):String;
	public function getFoldAt(row:Int, col:Int):Dynamic;
	@:native("$toggleFoldWidget")
	public function toggleFoldWidgetRaw(row:Int, opt:Dynamic):AceRange;
	public function getAllFolds():Array<AceFold>;
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
	public function getOption(name:String):Dynamic;
	public function setOption(name:String, val:Dynamic):Void;
	//
	public var bgTokenizer:AceBgTokenizer;
	public var selection:AceSelection;
	// non-standard:
	public var gmlFile:gml.GmlFile;
}
extern class AceBgTokenizer {
	public function start(row:Int):Void;
}
@:native("AceUndoManager") extern class AceUndoManager {
	public function new():Void;
	public function isClean():Bool;
	public function markClean():Void;
}
typedef AcePos = { column: Int, row:Int };
typedef AceRange = { start: AcePos, end:AcePos };
typedef AceToken = { type:String, value:String, index:Int, start:Int };
typedef AceAnnotation = { row:Int, column:Int, type:String, text:String }
extern class AceFold {
	public var start:AcePos;
	public var end:AcePos;
	public var range:AceRange;
	public var subFolds:Array<AceFold>;
}
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
