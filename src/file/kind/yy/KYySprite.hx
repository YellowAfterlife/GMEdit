package file.kind.yy;

import editors.EditSprite;
import file.FileKind;
import gml.file.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class KYySprite extends FileKind {
	public static var inst:KYySprite = new KYySprite();
	public function new() {
		super();
	}
	override public function init(file:GmlFile, data:Dynamic):Void {
		file.editor = new EditSprite(file);
	}
}
