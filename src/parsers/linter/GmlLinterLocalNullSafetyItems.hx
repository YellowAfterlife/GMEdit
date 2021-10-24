package parsers.linter;
import gml.GmlImports;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
using tools.NativeArray;

/**
 * Casting T? to T is allowed inside conditions that check for value being != undefined.
 * The current implementation is very simple and only works for local variables.
 * @author YellowAfterlife
 */
@:access(parsers.linter.GmlLinter)
@:forward
abstract GmlLinterLocalNullSafetyItems(Array<GmlLinterLocalNullSafetyItem>)
from Array<GmlLinterLocalNullSafetyItem>
{
	public function mergeItems(items:GmlLinterLocalNullSafetyItems) {
		for (nsi2 in items) {
			var nsi = inline this.findFirst((nsi) -> nsi.name == nsi2.name);
			if (nsi != null) {
				if (nsi.status != null && nsi.status != nsi2.status) nsi.status = null;
			} else this.push(nsi2);
		}
	}
	public function prepatch(linter:GmlLinter):Void {
		var imp:GmlImports = linter.getImports();
		if (imp == null) return;
		for (item in this) {
			if (item.status == null) continue;
			var t = imp.localTypes[item.name];
			if (t.getKind() == KNullable) {
				item.hasType = true;
				item.type = t;
				imp.localTypes[item.name] = item.status ? t.unwrapParam() : GmlTypeDef.undefined;
			}
		}
	}
	public function elsepatch(linter:GmlLinter):Void {
		var imp:GmlImports = linter.getImports();
		if (imp == null) return;
		for (item in this) if (item.hasType) {
			if (item.status) {
				imp.localTypes[item.name] = GmlTypeDef.undefined;
			} else {
				imp.localTypes[item.name] = item.type.unwrapParam();
			}
		}
	}
	public function postpatch(linter:GmlLinter):Void {
		var imp:GmlImports = linter.getImports();
		if (imp == null) return;
		for (item in this) if (item.hasType) {
			imp.localTypes[item.name] = item.type;
			item.hasType = false;
			item.type = null;
		}
	}
}
class GmlLinterLocalNullSafetyItem {
	public var name:String;
	/** true -> not null, false -> is null */
	public var status:Bool;
	public var hasType:Bool;
	/** Used to store original type when swapping back and forth */
	public var type:GmlType;
	public function new(name:String, status:Bool) {
		this.name = name;
		this.status = status;
		this.hasType = false;
		this.type = null;
	}
}