package gml;
import ace.AceWrap;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlEnum extends GmlStruct {
	//
	public var names:Array<String> = [];
	public var items:Dictionary<Bool> = new Dictionary();
	public var compList:AceAutoCompleteItems = [];
	public var compMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	public var fieldComp:AceAutoCompleteItems = [];
	//
	public function new(name:String, orig:String) {
		super(name, orig);
	}
	//
}
