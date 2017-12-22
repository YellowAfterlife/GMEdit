package gml;
import ace.AceWrap;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlMacro extends GmlStruct {
	public var comp:AceAutoCompleteItem;
	public var expr:String;
	public function new(name:String, orig:String, expr:String) {
		super(name, orig);
		comp = new AceAutoCompleteItem(name, "macro", expr);
	}
	
}
