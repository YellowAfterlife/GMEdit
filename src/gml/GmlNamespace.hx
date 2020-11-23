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
	public var name:String;
	public var kind:Dictionary<AceTokenType> = new Dictionary();
	
	/** static (`Buffer.ptr`) completions */
	public var compStaticList:AceAutoCompleteItems = [];
	public var compStaticMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	public var docStaticMap:Dictionary<GmlFuncDoc> = new Dictionary();
	
	/** instance (`var b; b.ptr`) completions */
	public var compInstList:AceAutoCompleteItems = [];
	public var compInstMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	public var docInstMap:Dictionary<GmlFuncDoc> = new Dictionary();
	
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
