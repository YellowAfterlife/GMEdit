package gml;
import ace.AceWrap;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlGlobal extends GmlStruct {
	public var comp:AceAutoCompleteItem;
	public function new(name:String, orig:String) {
		super(name, orig);
		comp = new AceAutoCompleteItem(name, "globalvar");
	}
	
}
