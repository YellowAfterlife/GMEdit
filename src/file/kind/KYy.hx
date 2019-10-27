package file.kind;
import electron.Dialog;
import electron.FileSystem;
import gml.file.GmlFile.GmlFileNav;

import electron.FileWrap;
import file.FileKind;
import file.FileKindDetect;
import gml.file.GmlFile;
import tools.Dictionary;
import yy.YyBase;

/**
 * ...
 * @author YellowAfterlife
 */
class KYy extends FileKind {
	public static var inst:KYy = new KYy();
	private static var map:Dictionary<Array<FileKind>> = new Dictionary();
	public static function register(modelName:String, file:FileKind):Void {
		var arr = map[modelName];
		if (arr == null) {
			arr = [];
			map.set(modelName, arr);
		}
		arr.unshift(file);
	}
	override public function detect(path:String, data:Dynamic):FileKindDetect {
		var json:YyBase = data != null ? data : FileWrap.readYyFileSync(path);
		var kinds = map[tools.JsTools.or(json.resourceType, json.modelName)];
		if (kinds != null) for (kind in kinds) {
			var out = kind.detect(path, json);
			if (out != null) return out;
		}
		return super.detect(path, json);
	}
	override public function create(name:String, path:String, data:Dynamic, nav:GmlFileNav):GmlFile {
		var json:YyBase = data != null ? data : FileWrap.readYyFileSync(path);
		var opt:Int;
		var dunno = 'GMEdit doesn\'t know how to open YY type ${json.modelName}.';
		if (FileSystem.canSync) {
			opt = Dialog.showMessageBox({
				message: '$dunno What would you like to do?',
				buttons: [
					"Open as JSON",
					"Open in external editor",
					"Show in directory",
					"Do nothing",
				],
				defaultId: 3,
				cancelId: 3,
			});
		} else {
			opt = Dialog.showConfirm('$dunno Would you like to open it as JSON?') ? 0 : 3;
		}
		switch (opt) {
			case 0: return file.kind.misc.KJavaScript.inst.create(name, path, null, nav);
			case 1: return file.kind.misc.KExtern.inst.create(name, path, null, nav);
			case 2: FileWrap.showItemInFolder(path);
		}
		return null;
	}
}
