package ace.extern;
import js.html.Element;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("AceTooltip")
extern class AceTooltip {
	function new(parent:Element):Void;
	function getElement():Element;
	function setText(s:String):Void;
	function setHtml(html:String):Void;
	function setPosition(x:Float, y:Float):Void;
	function setClassName(c:String):Void;
	function show(?text:String, ?x:Float, ?y:Float):Void;
	function hide():Void;
	function getHeight():Float;
	function getWidth():Float;
	function destroy():Void;
}
