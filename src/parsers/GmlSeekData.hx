package parsers;
import ace.AceWrap;
import ace.extern.*;
import file.FileKind;
import gml.GmlAPI;
import gml.*;
import gml.type.GmlType;
import synext.GmlExtCoroutines;
import synext.GmlExtMFunc;
import tools.ArrayMap;
import tools.Dictionary;
using tools.NativeString;
using tools.NativeArray;

/**
 * Represents processed state of a file,
 * describing what definitions it had.
 * @author YellowAfterlife
 */
class GmlSeekData {
	/** path -> data */
	public static var map:Dictionary<GmlSeekData> = new Dictionary();
	private static var blank:GmlSeekData = new GmlSeekData(null);
	//
	public var kind:FileKind;
	public var main:String;
	
	// enums declared in this file
	public var enums:ArrayMap<GmlEnum> = new ArrayMap();
	
	// globalvars declared in this file
	public var globalVars:ArrayMap<GmlGlobalVar> = new ArrayMap();
	public var globalVarTypes:ArrayMap<GmlType> = new ArrayMap();
	
	// specific globals used in this file
	public var globalFields:ArrayMap<GmlGlobalField> = new ArrayMap();
	public var globalFieldComp:AceAutoCompleteItems = [];
	// ditto but with "global." prefix
	public var globalFullMap:Dictionary<GmlGlobalField> = new Dictionary();
	public var globalFullComp:AceAutoCompleteItems = [];
	/** `global.name = ...; /// @is {type}` */
	public var globalTypes:ArrayMap<GmlType> = new ArrayMap();
	
	// instance variables assigned in this file
	public var instFieldMap:Dictionary<GmlField> = new Dictionary();
	public var instFieldList:Array<GmlField> = [];
	public var instFieldComp:AceAutoCompleteItems = [];
	
	// macros declared in this file
	public var macros:ArrayMap<GmlMacro> = new ArrayMap();
	
	// macro functions in this file
	public var mfuncs:ArrayMap<GmlExtMFunc> = new ArrayMap();
	
	/** scope name -> local variables */
	public var locals:Dictionary<GmlLocals> = new Dictionary();
	
	public var kindList:Array<String> = [];
	public var kindMap:Dictionary<AceTokenType> = new Dictionary();
	
	public var comps:ArrayMap<AceAutoCompleteItem> = new ArrayMap();
	public var docs:ArrayMap<GmlFuncDoc> = new ArrayMap();
	
	// namespace hints
	public var fieldHints:ArrayMap<GmlSeekDataHint> = new ArrayMap();
	public var namespaceHints:ArrayMap<GmlSeekDataNamespaceHint> = new ArrayMap();
	
	/** namespace -> implements-list */
	public var namespaceImplements:Dictionary<Array<String>> = new Dictionary();
	
	// features
	public var imports:Dictionary<GmlImports> = null;
	public var hasCoroutines:Bool = false;
	public var hasGMLive:Bool = false;
	
	//
	public function new(kind:FileKind) {
		if (kind == null) kind = file.kind.gml.KGmlScript.inst;
		this.kind = kind;
	}
	
	public function addObjectHint(name:String, parentName:String) {
		var nhs = new GmlSeekDataNamespaceHint(name, parentName, true);
		namespaceHints.set(name, nhs);
	}
	
	public static function add(path:String, kind:FileKind) {
		if (map.exists(path)) return;
		var next = new GmlSeekData(kind);
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
		if (GmlAPI.version.config.indexingMode == Local) return;
		
		// todo: it might be <a bit> faster to merge changes instead
		
		// doc:
		for (d in prev.docs) {
			if (!next.docs.exists(d.name)) {
				GmlAPI.gmlDoc.remove(d.name);
			}
		}
		for (d in next.docs) {
			GmlAPI.gmlDoc.set(d.name, d);
		}
		
		// kind:
		for (k in prev.kindList) {
			if (!next.kindMap.exists(k)) GmlAPI.gmlKind.remove(k);
		}
		for (k in next.kindList) GmlAPI.gmlKind.set(k, next.kindMap[k]);
		
		// comp:
		for (c in prev.comps) {
			GmlAPI.gmlComp.remove(c);
		}
		for (c1 in next.comps) {
			GmlAPI.gmlComp.push(c1);
		}
		
		// enums:
		for (e in prev.enums) {
			for (comp in e.compList) GmlAPI.gmlComp.remove(comp);
			GmlAPI.gmlKind.remove(e.name);
			GmlAPI.gmlEnums.remove(e.name);
			GmlAPI.gmlEnumTypeComp.remove(e.typeComp);
		}
		for (e in next.enums) {
			for (comp in e.compList) GmlAPI.gmlComp.push(comp);
			GmlAPI.gmlEnums.set(e.name, e);
			GmlAPI.gmlKind.set(e.name, "enum");
			GmlAPI.gmlEnumTypeComp.push(e.typeComp);
		}
		
		// macros:
		for (m in prev.macros) {
			if (!next.macros.exists(m.name)) GmlAPI.gmlMacros.remove(m.name);
		}
		for (m in next.macros) GmlAPI.gmlMacros.set(m.name, m);
		
		// mfuncs:
		for (m in prev.mfuncs) {
			if (!next.mfuncs.exists(m.name)) GmlAPI.gmlMFuncs.remove(m.name);
		}
		for (m in next.mfuncs) GmlAPI.gmlMFuncs.set(m.name, m);
		
		//
		prev.globalVarTypes.forEach(function(s, t) {
			if (!next.globalTypes.exists(s)) GmlAPI.gmlTypes.remove(s);
		});
		next.globalVarTypes.forEach(function(s, t) {
			GmlAPI.gmlTypes[s] = t;
		});
		
		// global fields (delta)
		for (g in prev.globalFields) {
			if (next.globalFields[g.name] == g) continue;
			if (--g.refs <= 0) {
				GmlAPI.gmlGlobalFieldMap.remove(g.name);
				GmlAPI.gmlGlobalFieldComp.remove(g.comp);
				GmlAPI.gmlGlobalFullMap.remove(g.name);
				GmlAPI.gmlGlobalFullComp.remove(g.fullComp);
			}
		}
		for (g in next.globalFields) {
			if (prev.globalFields[g.name] == g) continue;
			if (++g.refs == 1) {
				GmlAPI.gmlGlobalFieldMap.set(g.name, g);
				GmlAPI.gmlGlobalFieldComp.push(g.comp);
				GmlAPI.gmlGlobalFullMap.set(g.name, g);
				GmlAPI.gmlGlobalFullComp.push(g.fullComp);
			}
		}
		
		prev.globalTypes.forEach(function(s, t) {
			if (!next.globalTypes.exists(s)) GmlAPI.gmlGlobalTypes.remove(s);
		});
		next.globalTypes.forEach(function(s, t) {
			GmlAPI.gmlGlobalTypes[s] = t;
		});
		
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
		
		// hints (not very smart):
		for (nsh in next.namespaceHints) {
			var ns = GmlAPI.ensureNamespace(nsh.namespace);
			if (nsh.parentSpace != null && (ns.parent == null || ns.parent.name != nsh.parentSpace)) {
				ns.parent = GmlAPI.ensureNamespace(nsh.parentSpace);
			}
			if (nsh.isObject != null) {
				ns.isObject = nsh.isObject;
				GmlAPI.gmlNamespaceComp[nsh.namespace].meta = nsh.isObject ? "object" : "namespace";
			}
		}
		
		for (nsName => arr0 in prev.namespaceImplements) {
			var ns = GmlAPI.gmlNamespaces[nsName];
			if (ns == null) continue;
			var arr1 = next.namespaceImplements[nsName];
			for (impName in arr0) {
				if (arr1 != null && arr1.contains(impName)) continue;
				ns.interfaces.remove(impName);
			}
		}
		for (nsName => arr1 in next.namespaceImplements) {
			var ns = GmlAPI.ensureNamespace(nsName);
			var arr0 = prev.namespaceImplements[nsName];
			for (impName in arr1) {
				if (arr0 != null && arr0.contains(impName)) continue;
				var impSpace = GmlAPI.ensureNamespace(impName);
				ns.interfaces.addn(impSpace);
			}
		}
		
		for (hint in prev.fieldHints) {
			var ns = GmlAPI.gmlNamespaces[hint.namespace];
			if (ns == null) continue;
			ns.removeFieldHint(hint.field, hint.isInst);
		}
		for (hint in next.fieldHints) {
			var ns = GmlAPI.ensureNamespace(hint.namespace);
			if (hint.parentSpace != null && (ns.parent == null || ns.parent.name != hint.parentSpace)) {
				ns.parent = GmlAPI.ensureNamespace(hint.parentSpace);
			}
			ns.addFieldHint(hint.field, hint.isInst, hint.comp, hint.doc, hint.type);
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
typedef GmlSeekData_implement = { namespace:String, interfSpace:String };
class GmlSeekDataNamespaceHint {
	public var namespace:String;
	public var parentSpace:String;
	public var isObject:Bool;
	public function new(namespace:String, parentSpace:String, isObject:Bool) {
		this.namespace = namespace;
		this.parentSpace = parentSpace;
		this.isObject = isObject;
	}
}
class GmlSeekDataHint {
	public var namespace:String;
	public var parentSpace:String;
	public var field:String;
	public var isInst:Bool;
	public var key:String;
	public var comp:AceAutoCompleteItem;
	public var doc:GmlFuncDoc;
	public var type:GmlType;
	public function new(namespace:String, isInst:Bool, field:String,
		comp:AceAutoCompleteItem, doc:GmlFuncDoc, parentSpace:String, type:GmlType
	) {
		this.namespace = namespace;
		this.parentSpace = parentSpace;
		this.field = field;
		this.isInst = isInst;
		this.doc = doc;
		this.comp = comp;
		this.type = type;
		this.key = namespace + (isInst ? ":" : ".") + field;
	}
	public function merge(hint:GmlSeekDataHint, ?preferExisting:Bool) {
		var cd0 = comp.doc;
		var cd1 = hint.comp.doc;
		var cdp = field + "(";
		if (cd0 == null) {
			comp.doc = cd1;
		} else if (cd0.startsWith(cdp)) {
			if (cd1 == null) {
				// OK!
			} else if (cd1.startsWith(cdp)) {
				comp.doc = cd1;
			} else {
				comp.doc = cd0 + "\n" + cd1;
			}
		} else {
			if (cd1 == null) {
				// OK!
			} else if (cd1.startsWith(cdp)) {
				comp.doc = cd1 + "\n" + cd0;
			} else {
				comp.doc = cd1;
			}
		}
		//
		if (hint.doc != null && (!preferExisting || doc == null)) doc = hint.doc;
		if (hint.type != null && (!preferExisting || type == null)) type = hint.type;
	}
}