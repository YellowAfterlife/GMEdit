package gml;
import gml.GmlVersion;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlVersionV23 extends GmlVersion {
	override public function hasColorLiterals():Bool {
		return Project.current.isGM2022;
	}
}