package ace;
import haxe.io.Path;
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
		var dir = Sys.getCwd();
		dir = Path.removeTrailingSlashes(dir);
		dir = Path.withoutDirectory(dir);
		var path = "bin/buildnumber.txt";
		if (dir == "src") path = "../" + path;
		sys.io.File.saveContent(path, out);
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
	public static inline function jsOr<T>(a:T, b:T):T {
		return untyped (a || b);
	}
	/** (a, b, c) -> (a || b) || c */
	public static macro function jsOrx<T>(exprs:Array<ExprOf<T>>):ExprOf<T> {
		var p = Context.currentPos();
		var q = macro @:pos(p) ace.AceMacro.jsOr(${exprs[0]}, ${exprs[1]});
		for (i in 2 ... exprs.length) {
			q = macro @:pos(p) ace.AceMacro.jsOr($q, ${exprs[i]});
		}
		return q;
	}
}
