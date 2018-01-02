package gml;
import ace.AceWrap;
import gml.GmlAPI;
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
	// enums declared in this file
	public var enumList:Array<GmlEnum> = [];
	public var enumMap:Dictionary<GmlEnum> = new Dictionary();
	// globalvars declared in this file
	public var globalVarList:Array<GmlGlobalVar> = [];
	public var globalVarMap:Dictionary<GmlGlobalVar> = new Dictionary();
	// specific globals used in this file
	public var globalFieldList:Array<GmlGlobalField> = [];
	public var globalFieldMap:Dictionary<GmlGlobalField> = new Dictionary();
	public var globalFieldComp:AceAutoCompleteItems = [];
	// macros declared in this file
	public var macroList:Array<GmlMacro> = [];
	public var macroMap:Dictionary<GmlMacro> = new Dictionary();
	/** scope name -> local variables */
	public var locals:Dictionary<GmlLocals> = new Dictionary();
	public var kind:Dictionary<String> = new Dictionary();
	public var comp:AceAutoCompleteItems = [];
	public var docList:Array<GmlFuncDoc> = [];
	public var docMap:Dictionary<GmlFuncDoc> = new Dictionary();
	//
	public function new() {
		
	}
	public static function apply(prev:GmlSeekData, next:GmlSeekData) {
		if (GmlAPI.version == GmlVersion.live) return;
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
		for (g in prev.globalVarList) {
			GmlAPI.gmlKind.remove(g.name);
			GmlAPI.gmlComp.remove(g.comp);
		}
		for (g in next.globalVarList) {
			GmlAPI.gmlKind.set(g.name, "globalvar");
			GmlAPI.gmlComp.push(g.comp);
		}
		// global fields (delta)
		for (g in prev.globalFieldList) {
			if (next.globalFieldMap[g.name] != null) continue;
			if (--g.refs <= 0) {
				GmlAPI.gmlGlobalFieldMap.remove(g.name);
				GmlAPI.gmlGlobalFieldComp.remove(g.comp);
			}
		}
		for (g in next.globalFieldList) {
			if (prev.globalFieldMap[g.name] != null) continue;
			if (++g.refs == 1) {
				GmlAPI.gmlGlobalFieldMap.set(g.name, g);
				GmlAPI.gmlGlobalFieldComp.push(g.comp);
			}
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
