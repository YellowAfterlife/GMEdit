package electron;
import haxe.extern.Rest;

/**
 * ...
 * @author YellowAfterlife
 */
extern class RawConsole {
	public function log(values:Rest<Any>):Void;
	public function error(values:Rest<Any>):Void;
	public function warn(values:Rest<Any>):Void;
}
