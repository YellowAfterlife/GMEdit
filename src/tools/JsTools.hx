package tools;
import haxe.macro.Expr;
import haxe.macro.Context;

/**
 * Ah, the JavaScript
 * @author YellowAfterlife
 */
class JsTools {
	/** null-conditional AND (a && b) */
	public static inline function nca<T>(a:Any, b:T):Null<T> {
		#if !macro
		return js.Syntax.code("(({0}) && ({1}))", a, b);
		#else
		return untyped (a && b);
		#end
	}
	/** raw JS (a || b) */
	public static inline function or<T>(a:T, b:T):T {
		#if !macro
		return js.Syntax.code("(({0}) || ({1}))", a, b);
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
	/** Haxe regexp literal to JS regexp literal */
	public static macro function rx(e:ExprOf<EReg>) {
		switch (e.expr) {
			case EConst(CRegexp(s, o)): {
				s = ~/\//g.replace(s, "\\/");
				var s = '/$s/$o';
				return macro (cast js.Syntax.code($v{s}):js.lib.RegExp);
			};
			default: throw Context.error("Expected a regexp literal", e.pos);
		}
	}
}
