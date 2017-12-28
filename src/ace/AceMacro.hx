package ace;
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ...
 * @author YellowAfterlife
 */
class AceMacro {
	public static macro function timestamp() {
		var now = Date.now();
		var out = DateTools.format(now, "%b %e, %Y");
		return macro $v{out};
	}
	public static macro function rxRule(tk:ExprOf<Dynamic>, rx:ExprOf<EReg>, ?nx:Expr) {
		switch (rx.expr) {
			case EConst(CRegexp(r, o)): {
				return macro rule($tk, $v{r}, $nx);
				//return macro { token: $tk, regex: untyped __js__($v{'/$r/$o'}), next: $nx }
			};
			default: {
				Context.error("Expected a regular expression literal", rx.pos);
				return macro null;
			};
		}
	}
	public static var jsThis(get, never):Dynamic;
	private static inline function get_jsThis():Dynamic {
		#if !macro
		return untyped __js__("this");
		#else
		return null;
		#end
	}
	public static macro function jsNew(args:Array<Expr>) {
		return { expr: ECall(macro untyped __new__, args), pos: Context.currentPos() };
	}
	public static inline function jsOr<T>(a:T, b:T):T {
		return untyped (a || b);
	}
}
