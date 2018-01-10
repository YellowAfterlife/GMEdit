package electron;
import haxe.Constraints.Function;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_Menu") extern class Menu {
	function new():Void;
	//
	function append(item:MenuItem):Void;
	function insert(pos:Int, item:MenuItem):Void;
	var items:Array<MenuItem>;
	//
	function popup(wnd:Dynamic, ?opt:MenuPopupOptions):Void;
	inline function popupAuto(?opt:MenuPopupOptions):Void {
		popup(Electron.remote.getCurrentWindow(), opt);
	}
	inline function popupAsync():Void {
		popupAuto({ async: true });
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
typedef MenuItemOptions = {
	?click:Function,
	?role:String,
	?type:String,
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
