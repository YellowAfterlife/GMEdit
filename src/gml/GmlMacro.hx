package gml;
import ace.AceWrap;
import ace.extern.*;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlMacro extends GmlStruct {
	public var comp:AceAutoCompleteItem;
	public var expr:String;
	public var config:String;
	public function new(name:String, orig:String, expr:String, config:String) {
		super(name, orig);
		this.expr = expr;
		this.config = config;
		this.comp = new AceAutoCompleteItem(name, "macro", expr);
	}
	
}
