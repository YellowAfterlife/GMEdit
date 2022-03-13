package electron;
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ...
 * @author YellowAfterlife
 */
class ElectronMacros {
	public static macro function setExternType<T>(t:ExprOf<Class<T>>, v:ExprOf<Class<T>>) {
		var p = Context.currentPos();
		return macro @:pos(p) {
			var val = $v;
			js.Syntax.code("window.{0} = {1}", $t, val);
			if (false && $t != val) {}
		}
	}
	public static macro function setExternTypeSafe<T>(t:ExprOf<Class<T>>, v:ExprOf<Class<T>>) {
		var p = Context.currentPos();
		return macro @:pos(p) {
			var val = $v;
			if (val == null) {
				throw (cast js.Syntax.code("\"Couldn't find {0}\"", $t):String);
			}
			js.Syntax.code("window.{0} = {1}", $t, val);
			if (false && $t != $v) {}
		}
	}
}