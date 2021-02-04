package file.kind.yy;

import editors.EditFont;
import file.FileKind;
import gml.file.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class KYyFont extends FileKind {
	public static var inst:KYyFont = new KYyFont();
	public function new() {
		super();
	}
	override public function init(file:GmlFile, data:Dynamic):Void {
		file.editor = new EditFont(file);
	}
}
