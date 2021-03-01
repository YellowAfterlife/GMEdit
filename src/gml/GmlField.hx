package gml;
import ace.AceWrap;
import ace.extern.*;

/**
 * Represents a single GML variable name as used across the project.
 * @author YellowAfterlife
 */
class GmlField {
	/** Number of files that this variable is currently used in */
	public var refs:Int = 0;
	public var name:String;
	public var comp:AceAutoCompleteItem;
	public function new(name:String, kind:String) {
		this.name = name;
		this.comp = new AceAutoCompleteItem(name, kind);
	}
}
