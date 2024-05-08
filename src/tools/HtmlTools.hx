package tools;
import haxe.DynamicAccess;
import js.html.*;
import haxe.extern.EitherType;


/**
 * Various helpers for js.html.*
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
	public static inline function querySelectorAllAuto<T:Element>(el:EitherType<Document, Element>, selectors:String, ?c:Class<T>):ElementListOf<T> {
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
	public static function setDatasetValue(el:Element, key:String, value:String) {
		var dataset:DynamicAccess<String> = cast el.dataset;
		if (value == null) {
			if (dataset[key] == null) return false;
			js.Syntax.delete(dataset, key);
			return true;
		} else {
			if (dataset[key] == value) return false;
			dataset[key] = value;
			return true;
		}
	}
	public static function setDatasetFlag(el:Element, key:String, value:Bool) {
		var dataset:DynamicAccess<String> = cast el.dataset;
		if (value) {
			dataset[key] = "";
		} else {
			js.Syntax.delete(dataset, key);
		}
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

	/** Set the selected value for a select element to the provided value */
	public static function setSelectedValue(element: SelectElement, selectedValue: String) {
		var value:OptionElement = cast element.querySelector('option[value="${selectedValue}"]');
		if (value != null) {
			value.selected = true;
		}
	}

	public static function prettifyInputRange(element: InputElement) {
		var event = () -> {
			var min = Std.parseFloat(element.min);
			var max = Std.parseFloat(element.max);
			var value = Std.parseFloat(element.value);
			var percentage = (value-min)/(max-min)*100;
			element.style.background = 'linear-gradient(to right, var(--color-primary) 0%, var(--color-primary) ' + percentage + '%, rgba(128, 128, 128, 0.5) ' + percentage + '%, rgba(128, 128, 128, 0.5) 100%)';
		};
		element.addEventListener('input', event);
		event();
	}
	
	public static function moveOffScreen(element:Element) {
		element.style.position = "absolute";
		element.style.top = "-99999px";
	}
	
	public static function setTitleLines(el:Element, lines:Array<String>) {
		el.title = lines.join("\n");
		return el;
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