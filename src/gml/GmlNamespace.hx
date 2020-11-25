package gml;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import tools.ArrayMap;
import tools.ArrayMapSync;
import tools.Dictionary;
import ace.extern.*;

/**
 * A namespace is a set of static and/or instance fields belonging to some context.
 * It is used for both syntax highlighting and auto-completion.
 * @author YellowAfterlife
 */
class GmlNamespace {
	public static var blank(default, null):GmlNamespace = new GmlNamespace("");
	static inline var maxDepth = 128;
	
	public var name:String;
	public var parent:GmlNamespace = null;
	public var isObject:Bool = false;
	
	public var kind:Dictionary<AceTokenType> = new Dictionary();
	
	/** static (`Buffer.ptr`) completions */
	public var compStatic:ArrayMap<AceAutoCompleteItem> = new ArrayMap();
	
	public var docStaticMap:Dictionary<GmlFuncDoc> = new Dictionary();
	public function getStaticDoc(name:String):GmlFuncDoc {
		var q = this, n = 0;
		while (q != null && ++n <= maxDepth) {
			var d = q.docStaticMap[name];
			if (d != null) return d;
			q = q.parent;
		}
		return null;
	}
	
	/** instance (`var b; b.ptr`) completions */
	public var compInst:ArrayMapSync<AceAutoCompleteItem> = new ArrayMapSync();
	private var compInstCache:AceAutoCompleteItems = new AceAutoCompleteItems();
	private var compInstCacheID:Int = 0;
	public function getInstComp():AceAutoCompleteItems {
		// if this is not an object and there is no parent, the completion array is what we want:
		if (parent == null && !isObject) return compInst.array;
		
		// if completions cache is up to date, return it:
		var maxID = compInst.changeID;
		var par = parent, n = 0;
		while (par != null && ++n <= maxDepth) {
			var parID = par.compInst.changeID;
			if (parID > maxID) maxID = parID;
			par = par.parent;
		}
		if (maxID == compInstCacheID) return compInstCache;
		
		// re-generate completions:
		var list = compInst.array.copy();
		compInstCacheID = maxID;
		compInstCache = list;
		
		var found = new Dictionary();
		for (c in list) found[c.name] = true;
		
		// fill out missing fields from parents:
		par = parent; n = 0;
		while (par != null && ++n < maxDepth) {
			var ql = par.compInst.array;
			var qi = ql.length;
			while (--qi >= 0) {
				var qc = ql[qi];
				if (found.exists(qc.name)) continue;
				found[qc.name] = true;
				list.unshift(qc);
			}
			par = par.parent;
		}
		// if this is an object, add built-in variables at the end of the list:
		if (isObject) for (c in GmlAPI.stdInstComp) list.push(c);
		//
		return list;
	}
	
	public var docInstMap:Dictionary<GmlFuncDoc> = new Dictionary();
	public function getInstDoc(name:String):GmlFuncDoc {
		var q = this, n = 0;
		while (q != null && ++n <= maxDepth) {
			var d = q.docInstMap[name];
			if (d != null) return d;
			q = q.parent;
		}
		return null;
	}
	
	public function new(name:String) {
		this.name = name;
	}
	
	public function addFieldHint(field:String, isInst:Bool, comp:AceAutoCompleteItem, doc:GmlFuncDoc) {
		kind[field] = doc != null ? "asset.script" : "field";
		if (doc != null) {
			var docs = isInst ? docInstMap : docStaticMap;
			docs[field] = doc;
		}
		if (comp != null && field != "") {
			var comps:ArrayMap<AceAutoCompleteItem> = isInst ? compInst : compStatic;
			comps[field] = comp;
		}
	}
	
	public function removeFieldHint(field:String, isInst:Bool) {
		kind.remove(field);
		var docs = isInst ? docInstMap : docStaticMap;
		docs.remove(field);
		
		var comps:ArrayMap<AceAutoCompleteItem> = isInst ? compInst : compStatic;
		comps.remove(field);
	}
	
	public function addStdInstComp() {
		for (item in GmlAPI.stdInstComp) {
			compInst[item.name] = item;
		}
	}
}
