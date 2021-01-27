package tools.macros;
import haxe.macro.Context;
import haxe.macro.Expr;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class SynSugar {
	public static macro function cfor(init, cond, post, expr) {
		#if !display
		var func = null;
		func = function(expr:haxe.macro.Expr) {
			return switch (expr.expr) {
			case EContinue: macro { $post; $expr; }
			case EWhile(_, _, _): expr;
			case ECall(macro cfor, _): expr;
			case EFor(_): expr;
			//case EIn(_): expr;
			default: haxe.macro.ExprTools.map(expr, func);
			}
		}
		expr = func(expr);
		#end
		return macro @:pos(Context.currentPos()) {
			$init;
			while ($cond) {
				$expr;
				$post;
			}
		};
	}
	
	public static macro function ematch(expr:Expr, match:Expr, then:Expr, ?not:Expr) {
		if (not == null) not = { expr: null, pos: null }; // macro { };
		return macro @:pos(Context.currentPos())
		switch ($expr) {
			case $match: $then;
			default: $not;
		}; 
	}
	
	public static macro function enmatch(expr:Expr, match:Expr, not:Expr, ?then:Expr) {
		if (then == null) then = macro { };
		return macro @:pos(Context.currentPos())
		switch ($expr) {
			case $match: $then;
			default: $not;
		}
	}
	
	public static macro function xmls(e:ExprOf<String>):ExprOf<String> {
		return switch (e) {
			case macro @:markup $v{(_s:String)}:
				var s:String = _s;
				s = s.substring(s.indexOf(">") + 1, s.lastIndexOf("<")); // (grab content inside the tag)
				var indent = "";
				var rx = ~/^([ \t]*\r?\n)([ \t]*)/;
				if (rx.match(s)) { // unindent if formatted accordingly
					var indent = rx.matched(2);
					if (indent != "") s = s.replace("\n" + indent, "\n");
					s = s.substring(rx.matched(1).length);
					// trim last linebreak:
					var n = s.length - 1;
					while (n > 0) switch (StringTools.fastCodeAt(s, n)) {
						case "\t".code, " ".code: n--;
						default: break;
					}
					if (StringTools.fastCodeAt(s, n) == "\n".code) {
						if (StringTools.fastCodeAt(s, n - 1) == "\r".code) n--;
						s = s.substring(0, n);
					}
				}
				macro $v{s};
			default: Context.error("Markup literal expected", e.pos);
		}
	}
}