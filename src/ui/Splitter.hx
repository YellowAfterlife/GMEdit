package ui;
import js.html.Element;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("GMEdit_Splitter")
extern class Splitter {
	function new(el:Element):Void;
	function getWidth():Float;
	function setWidth(w:Float):Void;
	static function syncMain():Void;
}
