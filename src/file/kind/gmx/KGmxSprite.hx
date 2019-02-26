package file.kind.gmx;

import editors.EditSprite;
import file.FileKind;
import gml.file.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmxSprite extends FileKind {
	public static var inst:KGmxSprite = new KGmxSprite();
	public function new() {
		super();
	}
	override public function init(file:GmlFile, data:Dynamic):Void {
		file.editor = new EditSprite(file);
	}
}
