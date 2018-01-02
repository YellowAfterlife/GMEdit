package gml;
import ace.AceWrap;

/**
 * Represents an unique global variable (global.some).
 * @author YellowAfterlife
 */
class GmlGlobalField {
	/** Number of files that this variable is currently used in */
	public var refs:Int = 0;
	public var name:String;
	public var comp:AceAutoCompleteItem;
	public function new(name:String) {
		this.name = name;
		this.comp = new AceAutoCompleteItem(name, "global");
	}
	
}
