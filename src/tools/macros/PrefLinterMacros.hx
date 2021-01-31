package tools.macros;
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ...
 * @author ...
 */
class PrefLinterMacros {
	public static macro function addf(add:Expr, name:Expr, fd:Expr) {
		var p = Context.currentPos();
		var get, set, def;
		switch (fd.expr) {
			case EField(e, field): {
				get = macro @:pos(p) function(q) return q.$field;
				set = macro @:pos(p) function(q, z) q.$field = z;
				def = macro @:pos(p) GmlLinterPrefs.defValue.$field;
			}
			default: {
				Context.error("Wanted a field access expression", p);
				return macro {};
			}
		}
		return macro $add($name, $get, $set, $def);
	}
}