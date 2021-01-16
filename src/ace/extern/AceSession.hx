package ace.extern;
import ace.extern.AcePos;
import ace.extern.AceRange;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
@:using(ace.extern.AceSession.AceSessionTools)
@:native("AceEditSession") extern class AceSession {
	public function new(context:EitherType<String, AceDocument>, mode:Dynamic);
	//
	/** Returns the total number of lines */
	public function getLength():Int;
	
	public function getTextRange(?range:AceRange):String;
	//
	public function getScrollLeft():Float;
	public function setScrollLeft(left:Float):Void;
	public function getScrollTop():Float;
	public function setScrollTop(top:Float):Void;
	//
	public var doc:AceDocument;
	public var foldWidgets:Array<String>;
	public function getFoldWidget(row:Int):String;
	public function getFoldAt(row:Int, col:Int):Dynamic;
	public function getFoldWidgetRange(row:Int):AceRange;
	@:native("$toggleFoldWidget")
	public function toggleFoldWidgetRaw(row:Int, opt:Dynamic):AceRange;
	public function getAllFolds():Array<AceFold>;
	public function addFold(label:String, range:AceRange):AceFold;
	//
	public function getValue():String;
	public function setValue(v:String):Void;
	public function remove(range:AceRange):Void;
	//
	public function setMode(s:String):Void;
	@:native("$modeId") private var modeIdRaw(default, never):String;
	public var modeId(get, never):String;
	private inline function get_modeId():String {
		return AceMacro.jsOr(modeIdRaw, getOption("mode"));
	}
	@:native("$mode") public var modeRaw(default, never):Dynamic;
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
	public var gmlFile:gml.file.GmlFile;
	public var gmlScopes:gml.GmlScopes;
	public var gmlEditor:editors.EditCode;
	public var gmlErrorMarker:AceMarker;
	public var gmlErrorMarkers:Array<AceMarker>;
}
class AceSessionTools {
	public static function getEOF(s:AceSession):AcePos {
		var n = s.getLength() - 1;
		if (n < 0) return new AcePos(0, 0);
		return new AcePos(s.getLine(n).length, n);
	}
}