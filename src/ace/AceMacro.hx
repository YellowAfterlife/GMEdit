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
			case EConst(CRegexp(r, o)): return macro rule($tk, $v{r}, $nx);
			default: throw Context.error("Expected a regular expression literal", rx.pos);
		}
	}
	
	public static macro function rxPush(tk:ExprOf<Dynamic>, rx:ExprOf<EReg>, ?nx:Expr) {
		switch (rx.expr) {
			case EConst(CRegexp(r, o)): return macro rpush($tk, $v{r}, $nx);
			default: throw Context.error("Expected a regular expression literal", rx.pos);
		}
	}
	
	public static var jsThis(get, never):Dynamic;
	private static inline function get_jsThis():Dynamic {
		#if !macro
		return js.Syntax.code("this");
		#else
		return null;
		#end
	}
	public static inline function jsOr<T>(a:T, b:T):T {
		#if !macro
		return js.Syntax.code("({0} || {1})", a, b);
		#else
		return untyped (a || b);
		#end
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
	
	public static macro function jsRx(e:ExprOf<EReg>) {
		switch (e.expr) {
			case EConst(CRegexp(s, o)): {
				s = ~/\//g.replace(s, "\\/");
				var s = '/$s/$o';
				return macro (cast js.Syntax.code($v{s}):js.lib.RegExp);
			};
			default: throw Context.error("Expected a regexp literal", e.pos);
		}
	}
	
	public static macro function jsDelete(e:Expr) {
		switch (e.expr) {
			case EField(e, field): {
				return macro js.Syntax.delete($e, $v{field});
			};
			default: throw Context.error("Expected a regexp literal", e.pos);
		}
	}
}
