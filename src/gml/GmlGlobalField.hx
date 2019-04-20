package gml;
import ace.AceWrap;
import ace.extern.*;

/**
 * Represents an unique global variable (global.some).
 * @author YellowAfterlife
 */
class GmlGlobalField extends GmlField {
	public function new(name:String) {
		super(name, "global");
	}
}
