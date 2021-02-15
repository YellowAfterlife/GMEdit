package file.kind.yy;

import editors.EditSound;
import file.FileKind;
import gml.file.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class KYySound extends FileKind {
	public static var inst:KYySound = new KYySound();
	public function new() {
		super();
	}
	override public function init(file:GmlFile, data:Dynamic):Void {
		file.editor = new EditSound(file);
	}

}
