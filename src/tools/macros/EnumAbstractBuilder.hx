package tools.macros;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
using StringTools;

/**
 * Generates a nice-to-access-in-JS extern for an `enum abstract`.
 * @author YellowAfterlife
 */
class EnumAbstractBuilder {
	private static function getAbstractType(t:Type):AbstractType {
		return switch (t) {
			case null: null;
			case TInst(_.get() => ct, _):
				switch (ct.kind) {
					case KAbstractImpl(_.get() => at): at;
					default: null;
				};
			case TAbstract(_.get() => at, _): at;
			default: null;
		}
	}
	public static macro function build():Array<Field> {
		var fields = Context.getBuildFields();
		var localType = Context.getLocalType();
		var at = getAbstractType(localType);
		var ct = TPath({
			pack: at.pack.copy(),
			name: at.name,
		});
		if (at == null) throw "Should be applied to an enum abstract";
		var tp = at.pack.concat([at.name]).join(".");
		var pos = Context.currentPos();
		
		var objFields:Array<ObjectField> = [];
		var objDecl:Expr = { expr: EObjectDecl(objFields), pos: pos };
		
		for (field in fields) {
			if (StringTools.startsWith(field.name, "__")) continue;
			if (field.access.contains(APrivate)) continue;
			switch (field.kind) {
				case FVar(t, e):
					if (field.access.contains(AStatic)) continue; // todo: property..?
					objFields.push({
						field: field.name,
						expr: macro $i{field.name}
					});
				case FFun(f) if (field.access.contains(AStatic)):
					objFields.push({
						field: field.name,
						expr: macro $i{field.name}
					});
				case FFun(f):
					var call:Expr = {
						expr: ECall(
							{ // _this.<name>
								expr: EField(macro _this, field.name),
								pos: pos,
							},
							f.args.map(function(arg) {
								return macro $i{arg.name};
							})
						),
						pos: pos
					};
					var fun:Function = {
						args: [{
							name: "_this",
							type: ct,
						}].concat(f.args),
						expr: macro return $call,
					};
					objFields.push({
						field: field.name,
						expr: { expr: EFunction(FAnonymous, fun), pos: pos },
					});
				default:
			}
		}
		
		fields = fields.concat((macro class Temp {
			@:keep static var __ready:Bool = (function() {
				var tp:String = $v{tp};
				var _hxClasses:tools.Dictionary<Any> = js.Syntax.code("$hxClasses");
				if (_hxClasses.exists(tp)) throw "Redefinition of " + tp;
				_hxClasses[tp] = $objDecl;
				return true;
			})();
		}).fields);
		return fields;
	}
	public static macro function buildExtern():Expr {
		var fields = Context.getBuildFields();
		
		var localType = Context.getLocalType();
		var typePath:String = switch (localType) {
			case null: null;
			case TAbstract(_.get() => at, _): at.pack.concat([at.name]).join(".");
			default: null;
		};
		if (typePath == null) throw "Should be called in an abstract type, got " + localType;
		
		var exprs:Array<Expr> = [macro var _extern = new tools.Dictionary<Any>()];
		for (fd in fields) {
			if (StringTools.startsWith(fd.name, "__")) continue;
			switch (fd.kind) {
				case FVar(t, e):
					if (fd.access.contains(AStatic)) continue;
				case FFun(f):
					
				default:
			}
		}
		exprs.push(macro {
			var _hxClasses:tools.Dictionary<Any> = js.Syntax.code("$hxClasses");
			_hxClasses[$v{typePath}] = _extern;
		});
		return macro $b{exprs};
		/*var initExprs:Array<Expr> = [macro var m = new tools.Dictionary<GmlTypeKind>()];
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
		return fields;*/
	}
}