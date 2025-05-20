package ace;
import haxe.extern.EitherType;
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
		var pretty = DateTools.format(now, "%b %e, %Y");
		var short = DateTools.format(now, "%F");
		var dir = Sys.getCwd();
		dir = Path.removeTrailingSlashes(dir);
		dir = Path.withoutDirectory(dir);
		var path = "bin";
		if (dir == "src") path = "../" + path;
		sys.io.File.saveContent('$path/buildnumber.txt', short);
		sys.io.File.saveContent('$path/builddate.txt', pretty);
		return macro $v{pretty};
	}
	
	public static macro function rxRule(tk:ExprOf<Dynamic>, rx:ExprOf<EitherType<EReg, Array<EReg>>>, ?nx:Expr) {
		switch (rx.expr) {
			case EConst(CRegexp(r, o)): return macro rule($tk, $v{r}, $nx);
			case EArrayDecl(values): {
				var rb = new StringBuf();
				for (ax in values) switch (ax.expr) {
					case EConst(CRegexp(r, o)): rb.add("(" + r + ")");
					default: throw Context.error("Expected a regular expression literal", ax.pos);
				}
				switch (tk.expr) {
					case EFunction(kind, f): {
						if (f.args.length != values.length) {
							throw Context.error("Argument count mismatch", tk.pos);
						}
					}
					default:
				}
				return macro rule($tk, $v{rb.toString()}, $nx);
			};
			default: throw Context.error("Expected a regular expression literal", rx.pos);
		}
	}
	
	public static macro function rxMatch(tk:ExprOf<Dynamic>, rx:ExprOf<EReg>, ?nx:Expr) {
		switch (rx.expr) {
			case EConst(CRegexp(r, o)): return macro rmatch($tk, $v{r}, $nx);
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
	
	public static var jsArgs(get, never):Array<Dynamic>;
	private static inline function get_jsArgs():Array<Dynamic> {
		#if !macro
		return js.Syntax.code("arguments");
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
			default: throw Context.error("Expected a x.y expression", e.pos);
		}
	}
}
