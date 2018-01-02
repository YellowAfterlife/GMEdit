package gml;
import ace.AceWrap;

/**
 * Represents a single globalvar declaration.
 * @author YellowAfterlife
 */
class GmlGlobalVar extends GmlStruct {
	public var comp:AceAutoCompleteItem;
	public function new(name:String, orig:String) {
		super(name, orig);
		comp = new AceAutoCompleteItem(name, "globalvar");
	}
	
}
