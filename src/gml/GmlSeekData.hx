package gml;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekData {
	/** path -> data */
	public static var map:Dictionary<GmlSeekData> = new Dictionary();
	private static var blank:GmlSeekData = new GmlSeekData();
	//
	public var main:String;
	public var enumList:Array<GmlEnum> = [];
	public var enumMap:Dictionary<GmlEnum> = new Dictionary();
	public var globalList:Array<GmlGlobal> = [];
	public var globalMap:Dictionary<GmlGlobal> = new Dictionary();
	public var macroList:Array<GmlMacro> = [];
	public var macroMap:Dictionary<GmlMacro> = new Dictionary();
	public var locals:Dictionary<GmlLocals> = new Dictionary();
	//
	public function new() {
		
	}
	public static function apply(prev:GmlSeekData, next:GmlSeekData) {
		if (prev == null) prev = blank;
		if (next == null) next = blank;
		// todo: it might be <a bit> faster to merge changes instead
		// enums:
		for (e in prev.enumList) {
			for (comp in e.compList) GmlAPI.gmlComp.remove(comp);
			GmlAPI.gmlKind.remove(e.name);
			GmlAPI.gmlEnums.remove(e.name);
		}
		for (e in next.enumList) {
			for (comp in e.compList) GmlAPI.gmlComp.push(comp);
			GmlAPI.gmlEnums.set(e.name, e);
			GmlAPI.gmlKind.set(e.name, "enum");
		}
		// globals:
		for (g in prev.globalList) {
			GmlAPI.gmlKind.remove(g.name);
			GmlAPI.gmlComp.remove(g.comp);
		}
		for (g in next.globalList) {
			GmlAPI.gmlKind.set(g.name, "globalvar");
			GmlAPI.gmlComp.push(g.comp);
		}
		// macros:
		for (m in prev.macroList) {
			GmlAPI.gmlKind.remove(m.name);
			GmlAPI.gmlComp.remove(m.comp);
		}
		for (m in next.macroList) {
			GmlAPI.gmlKind.set(m.name, "macro");
			GmlAPI.gmlComp.push(m.comp);
		}
		// (locals don't have to be added/removed)
	}
}
