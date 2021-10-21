package parsers.linter;
import gml.GmlAPI;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import haxe.ds.ReadOnlyArray;
import tools.Aliases.FoundError;
import parsers.linter.GmlLinterKind;
import tools.macros.GmlLinterMacros.*;

/**
 * ...
 * @author YellowAfterlife
 */
@:access(parsers.linter.GmlLinter)
class GmlLinterArrayLiteral {
	public static var outType:GmlType;
	public static function read(self:GmlLinter, oldDepth:Int, targetType:GmlType):FoundError {
		var newDepth = oldDepth + 1;
		
		var tupleTypes:ReadOnlyArray<GmlType> = null;
		var tupleHasRest = false;
		var tupleRestType:GmlType = null;
		var itemType:GmlType = null;
		if (targetType == null) {
			// OK!
		} else {
			targetType = targetType.resolve();
			if (targetType.getKind() == KTuple) {
				tupleTypes = targetType.unwrapParams();
			}
			else if (targetType.getKind() == KEnumTuple) {
				var ename = targetType.unwrapParam().getNamespace();
				var en = ename != null ? GmlAPI.gmlEnums[ename] : null;
				if (en != null) tupleTypes = en.tupleTypes;
			}
			else if (targetType.canCastTo(GmlTypeDef.anyArray)) {
				itemType = targetType.unwrapParam();
			}
			if (tupleTypes != null) {
				var t:GmlType = tupleTypes[tupleTypes.length - 1].resolve();
				if (t.getKind() == KRest) {
					tupleHasRest = true;
					tupleRestType = t.unwrapParam();
				}
			}
		}
		
		var closed = false;
		var seenComma = true;
		var index = 0;
		var autoType:GmlType = null;
		var q = self.reader;
		self.seqStart.setTo(q);
		while (q.loop) {
			switch (self.peek()) {
				case KSqbClose:
					self.skip();
					closed = true;
					break;
				case KComma:
					if (seenComma) {
						return self.readError("Unexpected `,`");
					} else {
						seenComma = true;
						self.skip();
					}
				default:
					if (!seenComma) return self.readExpect("a comma in values list");
					seenComma = false;
					
					rc(self.readExpr(newDepth, None, null, itemType));
					
					if (tupleTypes != null) {
						var tt = tupleTypes[index];
						if (tupleHasRest && index >= tupleTypes.length - 1) tt = tupleRestType;
						self.checkTypeCast(self.readExpr_currType, tt, "tuple literal", self.readExpr_currValue);
					} else if (itemType != null) {
						self.checkTypeCast(self.readExpr_currType, itemType, "array literal", self.readExpr_currValue);
					} else if (index == 0) {
						autoType = self.readExpr_currType;
					} else if (autoType != null) {
						if (!self.readExpr_currType.canCastTo(autoType)) autoType = null;
					}
					
					index += 1;
			}
		}
		
		if (!closed) return self.readSeqStartError("Unclosed [] literal");
		
		if (tupleTypes != null) {
			var lastTupleType:GmlType = tupleTypes[tupleTypes.length - 1].resolve();
			if (tupleHasRest) {
				if (index < tupleTypes.length - 1) {
					self.readSeqStartWarn('Expected a >=${tupleTypes.length-1}-value tuple, got a $index-value tuple');
				}
			} else if (index != tupleTypes.length) {
				self.readSeqStartWarn('Expected a ${tupleTypes.length}-value tuple, got a $index-value tuple');
			}
			outType = targetType;
		} else if (itemType != null) {
			outType = targetType;
		} else {
			outType = index > 0 ? GmlTypeDef.array(autoType) : GmlTypeDef.anyArray;
		}
		return false;
	}
}