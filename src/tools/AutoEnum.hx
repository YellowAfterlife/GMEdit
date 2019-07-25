package tools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;
import haxe.macro.Type;

/**
 * @author YellowAfterlife
 * IntEnum (https://yal.cc/haxe-c-style-enum-macros/)
 * with toString and parse auto-generated methods.
 */
@:noCompletion
class AutoEnum {
	public static macro function build(?kindName:String):Array<Field> {
		var pos = Context.currentPos();
		var autoKind:AutoEnumKind = switch (kindName != null ? kindName.toLowerCase() : null) {
			case null: ANone;
			case "int": AInt(false);
			case "bit": AInt(true);
			case "lq", "lower": AString(false);
			case "uq", "upper": AString(true);
			case "nq", "string", "str": AString(null);
			default: Context.error('"$kindName" is not a known kind.', pos);
		}
		var at:AbstractType = switch (Context.getLocalClass().get().kind) {
			case KAbstractImpl(_.get() => at): at;
			default: Context.error("This macro should only be applied to abstracts", pos);
		}
		var fields:Array<Field> = Context.getBuildFields();
		var isBit = autoKind.match(AInt(true));
		var nextIndex:Int = isBit ? 1 : 0;
		var getNameCases:Array<Case> = [];
		var getNameField:Field = null;
		var createCases:Array<Case> = [];
		var createField:Field = null;
		for (field in fields) {
			switch (field.name) {
				case "getName": getNameField = field;
				case "create": createField = field;
			}
			var value:String = null;
			switch (field.kind) {
				case FVar(t, { expr: EConst(CInt(int)) }): { // `var some = 1;`
					value = int;
					nextIndex = Std.parseInt(value);
					if (isBit) {
						nextIndex <<= 1;
						if (nextIndex == 0) {
							Context.error("Bit overflow (too many fields?)", pos);
						}
					} else nextIndex += 1;
				};
				case FVar(t, null): { // `var some;`
					switch (autoKind) {
						case ANone: {};
						case AInt(_): {
							value = Std.string(nextIndex);
							if (isBit) nextIndex <<= 1; else nextIndex += 1;
							field.kind = FVar(t, { expr: EConst(CInt(value)), pos: field.pos });
						};
						case AString(z): {
							value = field.name;
							if (z == true) value = value.toUpperCase();
							if (z == false) value = value.toLowerCase();
							field.kind = FVar(t, { expr: EConst(CString(value)), pos: field.pos });
						};
					}
				};
				default:
			}
			if (value != null) {
				var retExpr = { expr: EConst(CString(field.name)), pos: field.pos };
				var idxExpr = { expr: EConst(CInt(value)), pos: field.pos };
				getNameCases.push({
					values: [idxExpr],
					expr: macro return $retExpr
				});
				createCases.push({
					values: [retExpr],
					expr: macro return cast $idxExpr
				});
			}
		} // for (field in fields)
		//
		if (getNameField == null) {
			getNameField = (macro class Temp_getNameField {
				public function getName():String return null;
			}).fields[0];
			fields.push(getNameField);
		}
		switch (getNameField.kind) {
			case FFun(f): {
				f.expr = {
					expr: ESwitch(macro cast this, getNameCases, f.expr),
					pos: f.expr.pos
				};
			};
			default: Context.error("getName should be a function.", getNameField.pos);
		}
		//
		if (createField == null) {
			createField = (macro class Temp_createField {
				public static function parse(name:String) return cast null;
			}).fields[0];
			fields.push(createField);
		}
		/*if (isBit) {
			var ct = haxe.macro.TypeTools.toComplexType(at);
			fields.push((macro class Magic {
				public inline function has(flag:$ct):Bool {
					return (cast this) & (cast flag) == (cast flag);
				}
			}).fields[0]);
		}*/
		switch (createField.kind) {
			case FFun(f): {
				f.expr = {
					expr: ESwitch(macro name, createCases, f.expr),
					pos: f.expr.pos
				};
				f.ret = ComplexType.TPath({
					name: at.name,
					pack: at.pack,
				});
			};
			default: Context.error("parse should be a function.", createField.pos);
		}
		//
		return fields;
	} // build
}
private enum AutoEnumKind {
	ANone;
	AInt(bit:Bool);
	AString(upper:Bool);
}
