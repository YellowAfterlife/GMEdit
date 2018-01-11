package electron;
import haxe.Constraints.Function;
import haxe.extern.Rest;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_IPC") extern class IPC {
	public static function on(channel:String, listener:Function):Void;
	public static function send(channel:String, args:Rest<Dynamic>):Void;
}
