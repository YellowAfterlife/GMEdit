package file.kind.misc;
import gml.file.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class KKeybindings extends FileKind {
	public static var inst:KKeybindings = new KKeybindings();
	override public function init(file:GmlFile, data:Dynamic):Void {
		file.editor = new editors.EditKeybindings(file);
	}
}