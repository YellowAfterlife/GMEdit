package ace;
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ...
 * @author YellowAfterlife
 */
class AceMacro {
	public static macro function rule(tk:ExprOf<Dynamic>, rx:ExprOf<EReg>, ?nx:Expr) {
		switch (rx.expr) {
			case EConst(CRegexp(r, o)): {
				return macro rule1($tk, $v{r}, $nx);
				//return macro { token: $tk, regex: untyped __js__($v{'/$r/$o'}), next: $nx }
			};
			default: {
				Context.error("Expected a regular expression literal", rx.pos);
				return macro null;
			};
		}
	}
	public static macro function jsNew(args:Array<Expr>) {
		return { expr: ECall(macro untyped __new__, args), pos: Context.currentPos() };
	}
}
