package tools;
import haxe.Rest;
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
	
	/**
	 * ncf(a.b.c) -> (a.b && a.b.c)
	 * ncf(a.b.c()) -> (a.b && a.b.c())
	 * ncf(a.b.c, d) -> (a.b ? a.b.c : d)
	 */
	public static macro function ncf(e:Expr, ?defValue:Expr):Expr {
		var p = Context.currentPos();
		switch (e.expr) {
			case EField(obj, field), ECall(_ => { expr: EField(obj, field) }, _):
				if (defValue != null) switch (defValue) {
					case macro null: //
					default: return macro @:pos(p) ((cast $obj) ? $e : $defValue);
				}
				return macro @:pos(p) tools.JsTools.nca($obj, $e);
			default: throw Context.error("Expected a field access expression", p);
		}
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
		var p = Context.currentPos();
		switch (e.expr) {
			case EConst(CRegexp(s, o)): {
				s = ~/\//g.replace(s, "\\/");
				var s = '/$s/$o';
				return macro @:pos(p) (cast js.Syntax.code($v{s}):js.lib.RegExp);
			};
			default: throw Context.error("Expected a regexp literal", p);
		}
	}
	
	#if !macro
	@:noUsing public static function setImmediate(fn:haxe.Constraints.Function, rest:Rest<Any>):Void {
		var args = rest.toArray();
		var dynWindow:Dynamic = Main.window;
		if (dynWindow.setImmediate) {
			args.unshift(fn);
			dynWindow.setImmediate.apply(dynWindow, args);
		} else {
			args.unshift(0);
			args.unshift(fn);
			(cast Main.window.setTimeout:js.lib.Function).apply(dynWindow, args);
		}
	}
	#end
}
