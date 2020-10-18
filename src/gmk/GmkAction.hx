package gmk;
import gmx.SfGmx;

/**
 * ...
 * @author YellowAfterlife
 */
class GmkAction {
	static var impl = new GmkActionImpl();
	public static var errorText:String;
	public static function getCode(action:SfGmx):String {
		var code = impl.getCode(action);
		errorText = impl.errorText;
		return code;
	}
	public static function makeCodeBlock(code:String):SfGmx {
		return impl.makeCodeBlock(code);
	}
}