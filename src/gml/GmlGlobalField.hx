package gml;
import ace.AceWrap;
import ace.extern.*;

/**
 * Represents an unique global variable (global.some).
 * @author YellowAfterlife
 */
class GmlGlobalField extends GmlField {
	/// "global.name" as opposed to "name" in comp
	public var fullComp:AceAutoCompleteItem;
	public var hidden:Bool = false;
	public function new(name:String) {
		super(name, "global");
		this.fullComp = new AceAutoCompleteItem("global."+name, "global");
	}
}
