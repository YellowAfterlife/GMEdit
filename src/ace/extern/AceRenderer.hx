package ace.extern;
import js.html.Element;

/**
 * ...
 * @author YellowAfterlife
 */
extern class AceRenderer {
	function textToScreenCoordinates(row:Int, column:Int):{pageX:Float, pageY:Float};
	function screenToTextCoordinates(x:Float, y:Float):AcePos;
	var scroller:Element;
	var scrollBar:{element:Element};
	var lineHeight(default, never):Int;
	@:native("$gutterLayer") var __gutter:Dynamic;
}
