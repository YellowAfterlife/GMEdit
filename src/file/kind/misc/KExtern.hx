package file.kind.misc;
import electron.FileWrap;
import gml.file.GmlFile.GmlFileNav;

import file.FileKind;
import gml.file.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class KExtern extends FileKind {
	public static var inst:KExtern = new KExtern();
	public function new() {
		super();
		
	}
	override public function create(name:String, path:String, data:Dynamic, nav:GmlFileNav):GmlFile {
		FileWrap.openExternal(path);
		return null;
	}
}
