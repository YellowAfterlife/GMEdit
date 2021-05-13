package electron;
import electron.Menu;
import haxe.Constraints.Function;
import haxe.extern.EitherType;
import js.html.DivElement;
import js.html.Element;
import Main.document;
import js.html.LIElement;
import js.html.MouseEvent;
import js.html.SpanElement;
import js.html.UListElement;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class MenuFallback {
	public static var contextEvent:MouseEvent = null;
	public var items:Array<MenuItemFallback> = [];
	public var __element:UListElement;
	public var __then:Void->Void;
	//
	public function new() {
		__element = document.createUListElement();
		(cast __element).gmlMenu = this;
		__element.classList.add("popout-menu");
	}
	//
	public function clear():Void {
		tools.NativeArray.clear(items);
		HtmlTools.clearInner(__element);
	}
	
	public function append(item:MenuItemFallback):Void {
		item.__parent = this;
		items.push(item);
		__element.appendChild(item.__element);
	}
	
	public static function appendOpt(menu:Menu, opt:MenuItemOptions):MenuItem {
		var item = new MenuItem(opt);
		menu.append(item);
		return item;
	}
	
	public static function appendSep(menu:Menu, ?id:String):MenuItem {
		var item = new MenuItem({ type:Sep, id:id });
		menu.append(item);
		return item;
	}
	
	public function insert(pos:Int, item:MenuItemFallback):Void {
		item.__parent = this;
		items.insert(pos, item);
	}
	
	public function __hide() {
		var par = __element.parentElement;
		if (par != null && par.tagName == "LI") { // ul > li > ul - we're a sub-menu!
			((cast par.parentElement).gmlMenu:MenuFallback).__hide();
			return;
		}
		
		document.removeEventListener("mousedown", __outerClick);
		
		if (par != null) par.removeChild(__element);
		
		var cb = __then;
		if (cb != null) {
			__then = null;
			cb();
		}
	}
	
	private function __outerClick(e:MouseEvent) {
		var el:Element = cast e.target;
		while (el != null) {
			if (el == __element) return;
			el = el.parentElement;
		}
		__hide();
	}
	
	public function __update() {
		__element.clearInner();
		for (item in items) {
			item.__parent = this;
			item.__update();
			__element.appendChild(item.__element);
		}
	}
	
	public function popup(?opt:MenuPopupOptions):Void {
		__then = opt != null ? opt.callback : null;
		if (contextEvent != null) {
			__element.style.left = contextEvent.pageX + "px";
			__element.style.top = contextEvent.pageY + "px";
		}
		__update();
		
		document.addEventListener("mousedown", __outerClick);
		document.body.appendChild(__element);
	}
}
@:keep class MenuItemFallback {
	public var enabled:Bool;
	public var visible:Bool;
	public var checked:Bool;
	public var label:String;
	public var click:Function;
	public var submenu:MenuFallback;
	public var type:MenuItemType;
	//
	public var __element:LIElement;
	public var __label:SpanElement;
	public var __parent:MenuFallback = null;
	//
	public function new(opt:MenuItemOptions) {
		enabled = opt.enabled != false;
		visible = opt.visible != false;
		checked = opt.checked;
		label = opt.label;
		click = opt.click;
		type = opt.type;
		if (type == null) type = MenuItemType.Normal;
		//
		__element = document.createLIElement();
		__element.classList.add("popout-menu-" + (opt.type != null ? opt.type : MenuItemType.Normal));
		if (opt.label != null) {
			__label = document.createSpanElement();
			__label.appendChild(document.createTextNode(opt.label));
			__element.appendChild(__label);
		}
		if (click != null) __element.addEventListener("click", function(e:MouseEvent) {
			if (!enabled) return;
			if (__parent != null) __parent.__hide();
			if (click != null) click();
		});
		if (opt.submenu != null) {
			if (Std.is(opt.submenu, Array)) {
				var opts:Array<MenuItemOptions> = opt.submenu;
				submenu = new MenuFallback();
				for (init in opts) submenu.append(new MenuItemFallback(init));
			} else submenu = cast opt.submenu;
		}
	}
	
	public function __update() {
		__element.style.display = visible ? "" : "none";
		
		if (__label != null) {
			if (__label.parentElement == null) {
				// labels somehow go missing in IE11..?
				__element.prepend(__label);
			}
			if (label != __label.innerText) {
				__label.setInnerText(label);
			}
		}
		__element.setAttributeFlag("disabled", !enabled);
		
		if (checked != null) {
			__element.setAttributeFlag("checked", checked);
		}
		
		if (submenu != null) {
			submenu.__update();
			var submenuNode = submenu.__element;
			if (submenuNode.parentElement != __element) {
				if (submenuNode.parentElement != null) {
					submenuNode.parentElement.removeChild(submenuNode);
				}
				__element.appendChild(submenuNode);
			}
		}
	}
}