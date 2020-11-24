package gml;
import gml.GmlFuncDoc;
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
	
	public var kind:Dictionary<AceTokenType> = new Dictionary();
	
	/** static (`Buffer.ptr`) completions */
	public var compStaticList:AceAutoCompleteItems = [];
	public var compStaticMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	
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
	public var compInstList:AceAutoCompleteItems = [];
	public var compInstMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	public function getInstComp():AceAutoCompleteItems {
		var list = compInstList;
		if (parent != null) {
			// TODO: consider whether anyone can have enough variables for this to become a performance culprit
			list = list.copy();
			var found = new Dictionary();
			for (c in list) found[c.name] = true;
			var q = parent, n = 0;
			while (q != null && ++n <= maxDepth) {
				var ql = q.compInstList;
				var qi = ql.length;
				while (--qi >= 0) {
					var qc = ql[qi];
					if (found.exists(qc.name)) continue;
					found[qc.name] = true;
					list.unshift(qc);
				}
				q = q.parent;
			}
		}
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
			var compList = isInst ? compInstList : compStaticList;
			var compMap = isInst ? compInstMap : compStaticMap;
			// remove existing completion item if replacing
			var cc = compMap[field];
			if (cc != null) compList.remove(cc);
			// add the new one:
			compMap[field] = comp;
			compList.push(comp);
		}
	}
	
	public function removeFieldHint(field:String, isInst:Bool) {
		kind.remove(field);
		var docs = isInst ? docInstMap : docStaticMap;
		docs.remove(field);
		
		var compList = isInst ? compInstList : compStaticList;
		var compMap = isInst ? compInstMap : compStaticMap;
		var cc = compMap[field];
		if (cc != null) {
			compMap.remove(field);
			compList.remove(cc);
		}
	}
}
