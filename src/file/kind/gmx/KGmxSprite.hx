package file.kind.gmx;

import editors.PreviewSprite;
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
		file.editor = new PreviewSprite(file);
	}
}
