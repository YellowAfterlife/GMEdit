package gml.type;
import js.lib.RegExp;
import tools.JsTools;
using tools.NativeString;

/**
 * Represents resolved template types and/or constraints (<A, B:C>)
 * @author YellowAfterlife
 */
@:using(gml.type.GmlTypeTemplateItem)
class GmlTypeTemplateItem {
	public var name:String;
	public var regex:RegExp;
	public var constraint:String;
	public function new(name:String, ?ct:String) {
		this.name = name;
		regex = name.getWholeWordRegex("g");
		constraint = ct;
	}
	
	/** parses `T1` or `T1:constraint` */
	public static function parse(str:String):GmlTypeTemplateItem {
		var mt = JsTools.rx(~/^\s*(.+?)\s*:\s*(.+?)\s*$/).exec(str);
		if (mt != null) {
			return new GmlTypeTemplateItem(mt[1], mt[2]);
		} else {
			return new GmlTypeTemplateItem(str.trimBoth());
		}
	}
	
	/** parses `T1,T2` or `T1,T2:C2` */
	public static function parseSplit(str:String):Array<GmlTypeTemplateItem> {
		var arr = [];
		for (ts in str.splitRx(JsTools.rx(~/[,;]\s*/g))) {
			arr.push(GmlTypeTemplateItem.parse(ts));
		}
		return arr;
	}
	
	/** [T1, T2:C2] -> "<T1,T2:C2>" */
	public static function joinTemplateString(arr:Array<GmlTypeTemplateItem>, constraints:Bool):String {
		if (arr == null) return "";
		var r = "<";
		for (i => ti in arr) {
			if (i > 0) r += ",";
			r += ti.name;
			if (constraints && ti.constraint != null) r += ":" + ti.constraint;
		}
		return r + ">";
	}
	
	public static function toTemplateSelf(arr:Array<GmlTypeTemplateItem>):GmlType {
		var tsp = [];
		for (i => ti in arr) {
			tsp.push(GmlType.TTemplate(ti.name, i, GmlTypeDef.parse(ti.constraint)));
		}
		return TInst("self", tsp, KTemplateSelf);
	}
}
