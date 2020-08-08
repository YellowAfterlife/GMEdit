package gml;
import tools.Dictionary;
import ace.extern.*;

/**
 * A namespace is a set of static and/or instance fields belonging to some context.
 * It is used for both syntax highlighting and auto-completion.
 * @author YellowAfterlife
 */
class GmlNamespace {
	public var kind:Dictionary<AceTokenType> = new Dictionary();
	
	/** static (`Buffer.ptr`) completions */
	public var compStaticList:AceAutoCompleteItems = [];
	public var compStaticMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	
	/** instance (`var b; b.ptr`) completions */
	public var compInstList:AceAutoCompleteItems = [];
	public var compInstMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	
	
	public var docs:Dictionary<GmlFuncDoc> = new Dictionary();
	
	public function new() {
		//
	}
	
	public function addFieldHint(field:String, isInst:Bool, comp:AceAutoCompleteItem, doc:GmlFuncDoc) {
		kind[field] = doc != null ? "asset.script" : "field";
		if (doc != null && isInst) docs[field] = doc;
		if (comp != null) {
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
		if (isInst) docs.remove(field);
		
		var compList = isInst ? compInstList : compStaticList;
		var compMap = isInst ? compInstMap : compStaticMap;
		var cc = compMap[field];
		if (cc != null) {
			compMap.remove(field);
			compList.remove(cc);
		}
	}
}
