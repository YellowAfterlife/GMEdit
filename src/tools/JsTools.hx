package tools;
import haxe.macro.Expr;
import haxe.macro.Context;

/**
 * Ah, the JavaScript
 * @author YellowAfterlife
 */
class JsTools {
	public static inline function or<T>(a:T, b:T):T {
		#if !macro
		return js.Syntax.code("({0} || {1})", a, b);
		#else
		return untyped (a || b);
		#end
	}
	/** (a, b, c) -> (a || b) || c */
	public static macro function orx<T>(exprs:Array<ExprOf<T>>):ExprOf<T> {
		var p = Context.currentPos();
		var q = macro @:pos(p) tools.JsTools.or(${exprs[0]}, ${exprs[1]});
		for (i in 2 ... exprs.length) {
			q = macro @:pos(p) tools.JsTools.or($q, ${exprs[i]});
		}
		return q;
	}
}
