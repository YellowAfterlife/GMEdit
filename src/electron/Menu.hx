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
	/**
	 * Just about every GMEdit icon is in the same directory so I'd rather have a shortcut.
	 */
	public static inline function silkIcon(name:String):String {
		return Main.modulePath + ("/icons/silk/" + name + ".png");
	}
	
	function new():Void;
	//
	function clear():Void;
	function append(item:MenuItem):Void;
	inline function appendOpt(opt:MenuItemOptions):MenuItem {
		return MenuFallback.appendOpt(this, opt);
	}
	inline function appendSep(?id:String):MenuItem {
		return MenuFallback.appendSep(this, id);
	}
	function insert(pos:Int, item:MenuItem):Void;
	var items:Array<MenuItem>;
	//
	function popup(?opt:MenuPopupOptions):Void;
	private inline function popupAuto(?opt:MenuPopupOptions):Void {
		popup(opt);
	}
	inline function popupSync(e:MouseEvent):Void {
		MenuFallback.contextEvent = e;
		popupAuto({});
	}
	inline function popupAsync(e:MouseEvent, ?fn:Void->Void):Void {
		MenuFallback.contextEvent = e;
		popupAuto({ async: true, callback: fn });
	}
	//
	static function setApplicationMenu(menu:Menu):Void;
}
typedef MenuPopupOptions = {
	?x:Int,
	?y:Int,
	?async:Bool,
	?positioningItem:Int,
	?callback:Void->Void,
};
@:native("Electron_MenuItem") extern class MenuItem {
	function new(opt:MenuItemOptions);
	var enabled:Bool;
	var visible:Bool;
	var checked:Bool;
	var label:String;
	var click:Function;
	var submenu:Menu;
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
