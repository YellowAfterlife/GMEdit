package file.kind.yy;

import editors.sprite.EditSprite;
import gml.Project;
import editors.sprite.PreviewSprite;
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
		if (Project.current.yyUsesGUID) {
			file.editor = new PreviewSprite(file);
		} else {
			file.editor = new EditSprite(file);
		}
	}
}
