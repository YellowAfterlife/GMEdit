package tools;
import gml.GmlFile;
import js.html.DivElement;
import js.html.Document;
import js.html.Element;
import js.html.MouseEvent;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
class HtmlTools {
	private static inline function asElement(el:EitherType<Document, Element>):Element {
		return cast el;
	}
	/** For when you are 100% sure that you are getting Elements in querySelector */
	public static inline function querySelectorEls(el:EitherType<Document, Element>, selectors:String):ElementList {
		return cast asElement(el).querySelectorAll(selectors);
	}
	public static inline function querySelectorAuto<T:Element>(
		el:EitherType<Document, Element>, selectors:String, ?c:Class<T>
	):T {
		return cast asElement(el).querySelector(selectors);
	}
}
extern class ElementList implements ArrayAccess<Element> {
	public var length(default, never):Int;
	public function item(index:Int):Element;
}
