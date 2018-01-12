package yy;
import gml.Project;
import parsers.GmlEvent;

/**
 * ...
 * @author YellowAfterlife
 */
class YyEvent {
	public static function toPath(type:Int, numb:Int, eid:YyGUID) {
		var ename = GmlEvent.getTypeNameCap(type);
		if (type == GmlEvent.typeCollision) {
			return ename + "_" + eid + ".gml";
		}
		return ename + "_" + numb + ".gml";
	}
	public static function toString(type:Int, numb:Int, oid:YyGUID) {
		var name = null;
		if (type == GmlEvent.typeCollision) {
			name = Project.current.yyObjectNames.get(oid);
		}
		return GmlEvent.toString(type, numb, name);
	}
	public static function fromString(name:String) {
		var data = GmlEvent.fromString(name);
		if (data != null && data.name != null) {
			data.obj = Project.current.yyObjectGUIDs[name];
		}
		return data;
	}
}
