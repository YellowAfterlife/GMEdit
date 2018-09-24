package parsers;
import ace.AceWrap;
import ace.extern.*;
import gml.GmlAPI;
import gml.*;
import tools.Dictionary;

/**
 * Represents processed state of a file,
 * describing what definitions it had.
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
	
	// instance variables assigned in this file
	public var instFieldMap:Dictionary<GmlGlobalField> = new Dictionary();
	public var instFieldList:Array<GmlGlobalField> = [];
	public var instFieldComp:AceAutoCompleteItems = [];
	
	// macros declared in this file
	public var macroList:Array<GmlMacro> = [];
	public var macroMap:Dictionary<GmlMacro> = new Dictionary();
	
	/** scope name -> local variables */
	public var locals:Dictionary<GmlLocals> = new Dictionary();
	
	public var kindList:Array<String> = [];
	public var kindMap:Dictionary<String> = new Dictionary();
	
	public var compList:AceAutoCompleteItems = [];
	public var compMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	
	public var docList:Array<GmlFuncDoc> = [];
	public var docMap:Dictionary<GmlFuncDoc> = new Dictionary();
	
	// features
	public var imports:Dictionary<GmlImports> = null;
	public var hasCoroutines:Bool = false;
	public var hasGMLive:Bool = false;
	
	//
	public function new() {
		
	}
	public static function add(path:String) {
		if (map.exists(path)) return;
		var next = new GmlSeekData();
		map.set(path, next);
		apply(path, null, next);
	}
	public static function remove(path:String) {
		var curr = map[path];
		if (curr != null) {
			apply(path, curr, null);
			map.remove(path);
		}
	}
	public static function rename(pathOld:String, pathNew:String) {
		var curr = map[pathOld];
		if (curr != null) {
			map.remove(pathOld);
			map.set(pathNew, curr);
		}
	}
	public static function apply(path:String, prev:GmlSeekData, next:GmlSeekData) {
		if (prev == null) prev = blank;
		if (next == null) next = blank;
		
		// imports are copied over from previous known version:
		if (next.imports == null) next.imports = prev.imports;
		
		// single-file programs don't do incremental changes
		// because API context is changed on tab switch:
		if (GmlAPI.version == GmlVersion.live) return;
		
		// todo: it might be <a bit> faster to merge changes instead
		
		// doc:
		for (d in prev.docList) {
			if (!next.docMap.exists(d.name)) {
				GmlAPI.gmlDoc.remove(d.name);
			}
		}
		for (d in next.docList) {
			GmlAPI.gmlDoc.set(d.name, d);
		}
		
		// kind:
		for (k in prev.kindList) {
			if (!next.kindMap.exists(k)) GmlAPI.gmlKind.remove(k);
		}
		for (k in next.kindList) GmlAPI.gmlKind.set(k, next.kindMap[k]);
		
		// comp:
		for (c in prev.compList) {
			GmlAPI.gmlComp.remove(c);
		}
		for (c1 in next.compList) {
			GmlAPI.gmlComp.push(c1);
		}
		
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
		
		// macros:
		for (m in prev.macroList) {
			if (!next.macroMap.exists(m.name)) GmlAPI.gmlMacros.remove(m.name);
		}
		for (m in next.macroList) GmlAPI.gmlMacros.set(m.name, m);
		
		// global fields (delta)
		for (g in prev.globalFieldList) {
			if (next.globalFieldMap[g.name] == g) continue;
			if (--g.refs <= 0) {
				GmlAPI.gmlGlobalFieldMap.remove(g.name);
				GmlAPI.gmlGlobalFieldComp.remove(g.comp);
			}
		}
		for (g in next.globalFieldList) {
			if (prev.globalFieldMap[g.name] == g) continue;
			if (++g.refs == 1) {
				GmlAPI.gmlGlobalFieldMap.set(g.name, g);
				GmlAPI.gmlGlobalFieldComp.push(g.comp);
			}
		}
		
		// instance fields (delta)
		for (fd in prev.instFieldList) {
			if (next.instFieldMap[fd.name] == fd) continue;
			if (--fd.refs <= 0) {
				GmlAPI.gmlInstFieldMap.remove(fd.name);
				GmlAPI.gmlInstFieldComp.remove(fd.comp);
			}
		}
		for (fd in next.instFieldList) {
			if (prev.instFieldMap[fd.name] == fd) continue;
			if (++fd.refs == 1) {
				GmlAPI.gmlInstFieldMap.set(fd.name, fd);
				GmlAPI.gmlInstFieldComp.push(fd.comp);
			}
		}
		
		if (prev.hasGMLive || next.hasGMLive) {
			ui.GMLive.update(path, next.hasGMLive);
		}
		
		var file = gml.file.GmlFile.current;
		if (file != null && file.path == path) {
			var update = false;
			if (prev.hasCoroutines != next.hasCoroutines) {
				GmlExtCoroutines.update(next.hasCoroutines);
				update = true;
			}
			if (update) {
				Main.aceEditor.session.bgTokenizer.start(0);
			}
		}
		
		// (locals don't have to be added/removed)
	}
}
