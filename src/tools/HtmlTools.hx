package tools;
import gml.file.GmlFile;
import js.html.DOMTokenList;
import js.html.DivElement;
import js.html.Document;
import js.html.Element;
import js.html.MouseEvent;
import haxe.extern.EitherType;
import js.html.Node;

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
	
	public static function clearInner(el:Element) {
		el.innerHTML = "";
	}
	public static function setInnerText(el:Element, text:String) {
		el.innerHTML = "";
		el.appendChild(Main.document.createTextNode(text));
	}
	
	public static function setAttributeFlag(el:Element, attr:String, val:Bool) {
		if (val) {
			if (!el.hasAttribute(attr)) el.setAttribute(attr, "");
		} else {
			if (el.hasAttribute(attr)) el.removeAttribute(attr);
		}
	}
	public static function setTokenFlag(tl:DOMTokenList, name:String, val:Bool) {
		if (tl.contains(name) != val) tl.toggle(name);
	}
	public static function setDisplayFlag(el:Element, visible:Bool):Void {
		el.style.display = visible ? "" : "none";
	}
	
	public static inline function insertBeforeEl(ctr:Element, insertWhat:Element, beforeWhat:Element) {
		ctr.insertBefore(insertWhat, beforeWhat);
	}
	public static function insertAfterEl(ctr:Element, insertWhat:Element, afterWhat:Element) {
		var next = afterWhat.nextElementSibling;
		insertBeforeEl(ctr, insertWhat, next);
	}
	public static function insertBeforeSelf(el:Element, insertWhat:Element) {
		insertBeforeEl(el.parentElement, insertWhat, el);
	}
	public static function insertAfterSelf(el:Element, insertWhat:Element) {
		insertAfterEl(el.parentElement, insertWhat, el);
	}
}
extern class ElementList implements ArrayAccess<Element> {
	public var length(default, never):Int;
	public function item(index:Int):Element;
}
