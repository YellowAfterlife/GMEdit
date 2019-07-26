package tools.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLinterMacros {
	/** if ($expr) return true */
	public static macro function rc(expr:Expr):Expr {
		return macro @:pos(Context.currentPos()) if ($expr) return true;
	}
	
}