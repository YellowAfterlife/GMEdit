package gml;
import ace.AceWrap;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlEnum extends GmlStruct {
	//
	public static var map:Dictionary<GmlEnum> = new Dictionary();
	public static var list:Array<GmlEnum> = [];
	//
	public var names:Array<String> = [];
	public var items:Dictionary<Bool> = new Dictionary();
	public var compList:AceAutoCompleteItems = [];
	public var compMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	//
	public function new(name:String, orig:String) {
		super(name, orig);
	}
	//
}
