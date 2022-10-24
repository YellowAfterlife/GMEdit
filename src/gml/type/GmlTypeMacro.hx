package gml.type;
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlTypeMacro {
	public static macro function build():Array<Field> {
		var fields = Context.getBuildFields();
		var initExprs:Array<Expr> = [macro var m = new tools.Dictionary<GmlTypeKind>()];
		var initField:Field = null;
		for (fd in fields) {
			if (fd.name == "init") initField = fd;
			if (!fd.kind.match(FVar(_, _))) continue;
			if (fd.access.contains(AStatic)) continue;
			initExprs.push(macro m[$v{fd.name}] = $i{fd.name});
		}
		initExprs.push(macro var hxc:tools.Dictionary<Dynamic> = js.Syntax.code("$hxClasses"));
		initExprs.push(macro hxc["gml.type.GmlTypeKind"] = m);
		initExprs.push(macro return true);
		switch (initField.kind) {
			case null: Context.error("No init() in GmlTypeKind", Context.currentPos());
			case FFun(f): f.expr = macro $b{initExprs};
			default: Context.error("init() should be a function", Context.currentPos());
		}
		return fields;
	}
}