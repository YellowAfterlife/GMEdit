package tools;
import gml.GmlFile;
import js.html.DivElement;
import js.html.Element;
import js.html.MouseEvent;

/**
 * ...
 * @author YellowAfterlife
 */
class HtmlTools {
	/** For when you are 100% sure that you are getting Elements in querySelector */
	public static inline function querySelectorEls(el:Element, selectors:String):ElementList {
		return cast el.querySelectorAll(selectors);
	}
	public static inline function querySelectorAuto<T:Element>(
		el:Element, selectors:String, ?c:Class<T>
	):T {
		return cast el.querySelector(selectors);
	}
}
extern class ElementList implements ArrayAccess<Element> {
	public var length(default, never):Int;
	public function item(index:Int):Element;
}
