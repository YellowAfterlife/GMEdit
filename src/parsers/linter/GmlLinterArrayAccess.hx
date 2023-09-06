package parsers.linter;
import ace.AceGmlTools;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.type.GmlType;
import gml.type.GmlTypeCanCastTo;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTools;
import parsers.linter.GmlLinterArrayAccess;
import synext.GmlExtCoroutines;
import tools.Aliases;
import parsers.linter.GmlLinter;
import tools.JsTools;
import tools.macros.GmlLinterMacros.*;

/**
 * ...
 * @author YellowAfterlife
 */
@:access(parsers.linter.GmlLinter)
class GmlLinterArrayAccess {
	public static var outType:GmlType;
	public static var outKind:GmlLinterKind;
	public static function read(self:GmlLinter,
		nk:GmlLinterKind,
		newDepth:Int,
		currType:GmlType,
		currKind:GmlLinterKind,
		currValue:GmlLinterValue
	):FoundError {
		var isNull = nk == KNullSqb;
		
		// extract `Type` from `Type?` when doing `v?[indexer]`
		if ((isNull || self.prefs.implicitNullableCasts) && currType.isNullable()) currType = currType.unwrapParam();
		
		var isArray = false;
		var isArray2d = false;
		var isLiteral = false;
		var arrayType1:GmlType = null, arrayValue1:GmlLinterValue = null;
		var arrayType2:GmlType = null, arrayValue2:GmlLinterValue = null;
		var checkColon = true;
		switch (self.peek()) {
			case KQMark: { // map[?k]
				self.skip();
				rc(self.readExpr(newDepth));
				currType = currType.resolve();
				var mapMeta = switch (currType) {
					case null: null;
					case TSpecifiedMap(mm): mm;
					default: null;
				}
				if (mapMeta != null) {
					switch (self.expr.currValue) {
						case VString(_, k):
							try {
								k = haxe.Json.parse(k);
								var mapField = mapMeta.fieldMap[k];
								currType = mapField != null ? mapField.type : mapMeta.defaultType;
							} catch (_) {
								currType = mapMeta.defaultType;
							}
						default:
							self.checkTypeCast(self.expr.currType, GmlTypeDef.string, "map key", self.expr.currValue);
							currType = mapMeta.defaultType;
					}
				} else if (self.checkTypeCast(currType, GmlTypeDef.ds_map, "[?", currValue)) {
					self.checkTypeCast(self.expr.currType, currType.unwrapParam(0), "map key", self.expr.currValue);
					currType = currType.unwrapParam(1);
				} else currType = null;
			};
			case KOr: { // list[|i]
				self.skip();
				
				rc(self.readExpr(newDepth));
				self.checkTypeCast(self.expr.currType, GmlTypeDef.number, "list index", self.expr.currValue);
				
				currType = currType.resolve();
				if (self.checkTypeCast(currType, GmlTypeDef.ds_list, "[|", currValue)) {
					currType = currType.unwrapParam(0);
				} else currType = null;
			};
			case KDollar: { // struct[$k]
				self.skip();
				
				rc(self.readExpr(newDepth));
				self.checkTypeCast(self.expr.currType, GmlTypeDef.string, "struct key", self.expr.currValue);
				
				if (true) { // todo: validate that object is struct-like
					currType = currType.unwrapParam(0);
				} else currType = null;
			};
			case KHash: { // grid[#x, y]
				self.skip();
				
				rc(self.readExpr(newDepth));
				self.checkTypeCast(self.expr.currType, GmlTypeDef.number, "grid X", self.expr.currValue);
				
				rc(self.readCheckSkip(KComma, "a comma before second index"));
				rc(self.readExpr(newDepth));
				self.checkTypeCast(self.expr.currType, GmlTypeDef.number, "grid Y", self.expr.currValue);
				
				currType = currType.resolve();
				if (self.checkTypeCast(currType, GmlTypeDef.ds_grid, "[#", currValue)) {
					currType = currType.unwrapParam(0);
				} else currType = null;
			};
			case KAtSign: { // array[@i] or array[@i, k]
				self.skip();
				isArray = true;
				checkColon = false;
				
				rc(self.readExpr(newDepth));
				arrayType1 = self.expr.currType;
				arrayValue1 = self.expr.currValue;
				
				if (self.skipIf(self.peek() == KComma)) {
					isArray2d = true;
					rc(self.readExpr(newDepth));
					arrayType2 = self.expr.currType;
					arrayValue2 = self.expr.currValue;
				}
			};
			default: { // array[i] or array[i, k]
				isArray = true;
				
				rc(self.readExpr(newDepth));
				arrayType1 = self.expr.currType;
				arrayValue1 = self.expr.currValue;
				
				if (self.skipIf(self.peek() == KComma)) {
					isArray2d = true;
					rc(self.readExpr(newDepth));
					arrayType2 = self.expr.currType;
					arrayValue2 = self.expr.currValue;
				}
				if (isNull && self.skipIf(self.peek() == KComma)) { // whoops, a?[b,c,d]
					GmlLinterArrayLiteral.read(self, newDepth, null);
					isLiteral = true;
				}
			};
		}
		if (!isLiteral) rc(self.readCheckSkip(KSqbClose, "a closing `]` in array access"));
		if (isLiteral) {
			rc(self.readCheckSkip(KColon, "a colon in a ?: operator"));
			rc(self.readExpr(newDepth));
			currKind = KQMark;
		} else if (isNull && isArray && checkColon && self.peek() == KColon) { // whoops, a?[b]:c
			self.skip();
			rc(self.readExpr(newDepth));
			currKind = KQMark;
		} else {
			currKind = isNull ? KNullArray : KArray;
			if (isArray) for (pass in 0 ... (isArray2d ? 2 : 1)) {
				var arrayType = pass > 0 ? arrayType2 : arrayType1;
				var arrayValue = pass > 0 ? arrayValue2 : arrayValue1;
				currType = currType.resolve();
				var ck = currType.getKind();
				var enumTupleName = switch (currType) {
					case null: null;
					case TEnumTuple(enumName): ck = KTuple; enumName;
					default: null;
				};
				switch (ck) {
					case KCustomKeyArray: {
						currType = currType.resolve();
						var indexType = currType.unwrapParam(0);
						if (arrayType != null) self.checkTypeCast(arrayType, indexType, "array index", arrayValue);
						currType = currType.unwrapParam(1);
					};
					case KTuple: {
						if (arrayValue == null) { // unknown index
							self.checkTypeCast(arrayType, GmlTypeDef.number, "array index", arrayValue);
							currType = null;
						} else switch (arrayValue) {
							case VNumber(i, _):
								var p;
								if (enumTupleName == null) {
									p = currType.unwrapParams();
								} else {
									var en = GmlAPI.gmlEnums[enumTupleName];
									p = en != null ? en.tupleTypes : null;
								}
								
								if (p == null) {
									currType = null;
								} else if (i < 0) {
									currType = null;
									self.addWarning('Out-of-bounds tuple access (index $i)');
								} else if (i >= p.length - 1) {
									var lastTupleType = p[p.length - 1].resolve();
									if (lastTupleType.getKind() == KRest) {
										currType = lastTupleType.unwrapParam();
									} else if (i >= p.length) {
										currType = null;
										self.addWarning('Out-of-bounds tuple access (index $i, length is ${p.length})');
									} else currType = lastTupleType;
								} else {
									currType = p[Std.int(i)];
								}
							default: currType = null;
						}
					};
					case KCustom if (currType.match(TInst(GmlExtCoroutines.arrayTypeName, _, _))): {
						switch (arrayValue) {
							case null:
								self.checkTypeCast(arrayType, GmlTypeDef.number, "array index", arrayValue);
								currType = null;
							case VNumber(f, _):
								var i = Std.int(f);
								switch (i) {
									case 0: currType = null; // result
									case 1: currType = GmlTypeDef.number; // case
									case 2: currType = GmlTypeDef.anyArray; // args
									default: currType = null;
								}
							default:
								currType = null;
						}
					};
					default: {
						if (arrayType != null) self.checkTypeCast(arrayType, GmlTypeDef.number, "array index", arrayValue);
						currType = currType.resolve();
						if (self.checkTypeCast(currType, GmlTypeDef.anyArray, "array access", currValue)) {
							currType = currType.unwrapParam(0);
						} else currType = null;
					};
				}
			}
		}
		outType = currType;
		outKind = currKind;
		return false;
	}
}