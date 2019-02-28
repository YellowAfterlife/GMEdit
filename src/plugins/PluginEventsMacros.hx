package plugins;
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ...
 * @author YellowAfterlife
 */
class PluginEventsMacros {
	public static macro function build():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) switch (field.kind) {
			case FieldType.FFun(fn): {
				field.access.push(Access.AInline);
				var tx = macro $v{field.name};
				var ax = macro $i{fn.args[0].name};
				var isSignal = false;
				if (fn.ret != null) switch (fn.ret) {
					case TPath({name:"Void"}): isSignal = true;
					default:
				}
				if (isSignal) {
					fn.expr = macro PluginAPI.signal($tx, $ax);
				} else {
					fn.expr = macro return PluginAPI.emit($tx, $ax);
				}
			};
			default:
		}
		return fields;
	}
}
