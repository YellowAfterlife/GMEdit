package tools;
import gml.file.GmlFile;
import js.html.DOMElement;
import js.html.DOMTokenList;
import js.html.DivElement;
import js.html.Document;
import js.html.Element;
import js.html.HTMLCollection;
import js.html.MouseEvent;
import haxe.extern.EitherType;
import js.html.Node;
import js.html.SelectElement;

/**
 * ...
 * @author YellowAfterlife
 */
class HtmlTools {
	private static inline function asElement(el:EitherType<Document, Element>):Element {
		return cast el;
	}
	
	public static function getAttributeAsInt(el:Element, attr:String, ?defValue:Int):Null<Int> {
		var val = el.getAttribute(attr);
		if (val == null) return defValue;
		var result = Std.parseInt(val);
		return result != null ? result : defValue;
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
	
	public static function setSelectValueWithoutOnChange(el:SelectElement, value:String, def:String) {
		var e = el.onchange;
		el.onchange = null;
		el.value = value;
		if (el.value == "") el.value = def;
		el.onchange = e;
	}
	
	public static function colIndexOf(col:HTMLCollection, item:Element, start:Int = 0):Int {
		var len = col.length;
		var i = start;
		if (i < 0) {
			i += len;
			if (i < 0) i = 0;
		}
		while (i < len) {
			if (col[i] == item) return i;
			i += 1;
		}
		return -1;
	}
	
	public static inline function getChildrenAs<T:Element>(el:DOMElement):ElementListOf<T> {
		return cast el.children;
	}
	
	public static function scrollIntoViewIfNeeded(el:Element):Void {
		if ((cast el).scrollIntoViewIfNeeded) {
			(cast el).scrollIntoViewIfNeeded();
		} else el.scrollIntoView();
	}
}
extern class ElementList implements ArrayAccess<Element> {
	public var length(default, never):Int;
	public function item(index:Int):Element;
}
extern class ElementListOf<T:Element> implements ArrayAccess<T> {
	public var length(default, never):Int;
	public function item(index:Int):T;
	public inline function indexOf(item:T, start:Int = 0):Int {
		return HtmlTools.colIndexOf(cast this, item, start);
	}
}