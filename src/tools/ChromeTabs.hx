package tools;
import js.html.Element;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("ChromeTabs") extern class ChromeTabs {
	public function new():Void;
	public function init(el:Element, opt:Dynamic):Void;
	public function addTab(tab:Dynamic):Dynamic;
}
