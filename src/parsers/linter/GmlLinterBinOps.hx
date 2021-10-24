package parsers.linter;

import parsers.linter.GmlLinterLocalNullSafetyItems;
import tools.Aliases;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import parsers.linter.GmlLinter.GmlLinterValue;
import tools.macros.GmlLinterMacros.*;
using tools.NativeArray;

/**
 * ...
 * @author YellowAfterlife
 */
@:access(parsers.linter.GmlLinter)
class GmlLinterBinOps extends GmlLinterHelper {
	public var nullSafety:GmlLinterLocalNullSafetyItems;
	/** `+¦ a - b;` -> `+ a - b¦;` */
	public function read(
		oldDepth:Int, firstType:GmlType, firstLVal:GmlLinterValue,
		firstOp:GmlLinterKind, firstVal:String, firstLocalName:String
	):FoundError {
		var newDepth = oldDepth + 1;
		var q = reader;
		var types = [firstType];
		var ops = [firstOp];
		var vals = [firstVal];
		var lvals = [firstLVal];
		var expr = linter.expr;
		var localNames = [firstLocalName];
		var nullSafety:GmlLinterLocalNullSafetyItems = [];
		while (q.loop) {
			rc(expr.read(newDepth, NoOps));
			localNames.push(expr.isLocalIdent ? expr.currName : null);
			for (nsi in expr.nullSafety) nullSafety.push(nsi);
			types.push(expr.currType);
			lvals.push(expr.currValue);
			var nk = peek();
			if (nk.isBinOp() || nk == KSet) {
				skip();
				ops.push(nk);
				vals.push(nextVal);
			} else break;
		}
		//
		var pmin = GmlLinterKind.getMaxBinPriority();
		var pmax = 0;
		for (op in ops) {
			var pc = op.getBinOpPriority();
			if (pc < pmin) pmin = pc;
			if (pc > pmax) pmax = pc;
		}
		//
		while (pmin <= pmax) {
			var i = 0;
			while (i < ops.length) {
				var op = ops[i];
				if (op.getBinOpPriority() == pmin) {
					var t1 = types[i];
					var t2 = types[i + 1];
					var lv1 = lvals[i], lv2 = lvals[i + 1];
					
					var nsName:String = null;
					if (localNames[i] != null && t2.equals(GmlTypeDef.undefined)) {
						nsName = localNames[i];
					} else if (localNames[i + 1] != null && t1.equals(GmlTypeDef.undefined)) {
						nsName = localNames[i + 1];
					}
					if (nsName != null) {
						var notNull = ops[i] == GmlLinterKind.KNE;
						var nsi = inline nullSafety.findFirst((nsi) -> nsi.name == nsName);
						if (nsi != null) {
							if (nsi.status != null && nsi.status != notNull) nsi.status = null;
						} else nullSafety.push(new GmlLinterLocalNullSafetyItem(nsName, notNull));
					}
					
					types[i] = linter.checkTypeCastOp(t1, lv1, t2, lv2, ops[i], vals[i]);
					types.splice(i + 1, 1);
					vals.splice(i, 1);
					ops.splice(i, 1);
				} else i += 1;
			}
			pmin += 1;
		}
		//
		expr.currType = types[0];
		this.nullSafety = nullSafety;
		return false;
	}
}