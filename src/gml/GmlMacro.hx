package gml;
import ace.AceWrap;
import ace.extern.*;

/**
 * Represents a single GML #macro definition.
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
