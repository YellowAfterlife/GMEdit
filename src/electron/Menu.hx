package electron;
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
@:native("Electron_Menu") extern class Menu {
	function new():Void;
	//
	function clear():Void;
	function append(item:MenuItem):Void;
	function insert(pos:Int, item:MenuItem):Void;
	var items:Array<MenuItem>;
	//
	function popup(wnd:Dynamic, ?opt:MenuPopupOptions):Void;
	private inline function popupAuto(?opt:MenuPopupOptions):Void {
		popup(Electron != null ? Electron.remote.getCurrentWindow() : null, opt);
	}
	inline function popupAsync(e:MouseEvent):Void {
		MenuFallback.contextEvent = e;
		popupAuto({ async: true });
	}
}
@:keep class MenuFallback {
	public static var contextEvent:MouseEvent = null;
	public var items:Array<MenuItemFallback> = [];
	public var element:UListElement;
	//
	public function new() {
		element = document.createUListElement();
		element.classList.add("popout-menu");
	}
	//
	public function clear():Void {
		tools.NativeArray.clear(items);
		HtmlTools.clearInner(element);
	}
	public function append(item:MenuItemFallback):Void {
		item.parent = this;
		items.push(item);
		element.appendChild(item.element);
	}
	public function insert(pos:Int, item:MenuItemFallback):Void {
		item.parent = this;
		items.insert(pos, item);
	}
	private function outerClick(e:MouseEvent) {
		var el:Element = cast e.target;
		while (el != null) {
			if (el == element) return;
			el = el.parentElement;
		}
		hide();
	}
	public function hide() {
		document.removeEventListener("mousedown", outerClick);
		if (element.parentElement != null) {
			element.parentElement.removeChild(element);
		}
	}
	public function popup(wnd:Dynamic, ?opt:MenuPopupOptions):Void {
		if (contextEvent != null) {
			element.style.left = contextEvent.pageX + "px";
			element.style.top = contextEvent.pageY + "px";
		}
		for (item in items) item.update();
		document.addEventListener("mousedown", outerClick);
		document.body.appendChild(element);
	}
}
typedef MenuPopupOptions = {
	?x:Int, ?y:Int, ?async:Bool, ?positioningItem:Int,
};
@:native("Electron_MenuItem") extern class MenuItem {
	function new(opt:MenuItemOptions);
	var enabled:Bool;
	var visible:Bool;
	var checked:Bool;
	var label:String;
	var click:Function;
}
@:keep class MenuItemFallback {
	public var enabled:Bool;
	public var visible:Bool;
	public var checked:Bool;
	public var label:String;
	public var click:Function;
	//
	public var element:LIElement;
	public var labelEl:SpanElement;
	public var parent:MenuFallback = null;
	private var currLabel:String;
	//
	public function new(opt:MenuItemOptions) {
		enabled = opt.enabled != false;
		visible = opt.visible != false;
		checked = opt.checked;
		label = opt.label;
		click = opt.click;
		element = document.createLIElement();
		element.classList.add("popout-menu-" + (opt.type != null ? opt.type : MenuItemType.Normal));
		if (opt.label != null) {
			currLabel = opt.label;
			labelEl = document.createSpanElement();
			labelEl.appendChild(document.createTextNode(opt.label));
			element.appendChild(labelEl);
		}
		if (click != null) element.addEventListener("click", function(e:MouseEvent) {
			if (!enabled) return;
			if (parent != null) parent.hide();
			if (click != null) click();
		});
		if (opt.submenu != null) {
			var submenu:MenuFallback;
			if (Std.is(opt.submenu, Array)) {
				var opts:Array<MenuItemOptions> = opt.submenu;
				submenu = new MenuFallback();
				for (init in opts) submenu.append(new MenuItemFallback(init));
			} else submenu = cast opt.submenu;
			element.appendChild(submenu.element);
		}
	}
	public function update() {
		element.style.display = visible ? "" : "none";
		if (label != currLabel) {
			currLabel = label;
			labelEl.setInnerText(label);
		}
		element.setAttributeFlag("disabled", !enabled);
		if (checked != null) element.setAttributeFlag("checked", checked);
	}
}
typedef MenuItemOptions = {
	?click:Function,
	?role:String,
	?type:MenuItemType,
	?label:String,
	?sublabel:String,
	?accelerator:Dynamic,
	?icon:Dynamic,
	?enabled:Bool,
	?visible:Bool,
	?checked:Bool,
	?submenu:EitherType<Array<MenuItemOptions>, Menu>,
	?id:String,
	?position:String,
};
@:enum abstract MenuItemType(String) from String to String{
	var Normal:MenuItemType = "normal";
	var Sep:MenuItemType = "separator";
	var Sub:MenuItemType = "submenu";
	var Check:MenuItemType = "checkbox";
	var Radio:MenuItemType = "radio";
}
