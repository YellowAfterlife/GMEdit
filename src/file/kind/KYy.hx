package file.kind;
import electron.Dialog;
import electron.FileSystem;
import gml.file.GmlFile.GmlFileNav;
import js.lib.RegExp;
import tools.JsTools;

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
	static var rxModelName:RegExp = new RegExp("(?:"
		+ '\n  "resourceType":\\s*"(\\w+)"'
		+ "|"
		+ '\n    "modelName":\\s*"(\\w+)"'
	+ ")");
	override public function detect(path:String, data:Dynamic):FileKindDetect {
		var json:YyBase, isObject:Bool;
		if (data != null) {
			json = data;
			isObject = Reflect.isObject(json);
		} else try {
			json = FileWrap.readYyFileSync(path);
			isObject = true;
		} catch (x:Dynamic) {
			return super.detect(path, data);
		}
		//
		var model:String;
		if (isObject) {
			model = JsTools.or(json.resourceType, json.modelName);
		} else {
			var mt = rxModelName.exec(data);
			if (mt != null) {
				model = JsTools.or(mt[1], mt[2]);
			} else try {
				json = yy.YyJson.parse(data);
				isObject = true;
				model = JsTools.or(json.resourceType, json.modelName);
			} catch (x:Dynamic) {
				return super.detect(path, json);
			}
		}
		var kinds = map[model];
		var baseDetect = (cast FileKind.inst).detect;
		var isInvalid = false;
		if (kinds != null) for (kind in kinds) {
			var kindDetect = (cast kind).detect;
			if (kindDetect == baseDetect) return kind.detect(path, json);
			if (isInvalid) continue;
			if (!isObject) {
				try {
					json = yy.YyJson.parse(data);
				} catch (x:Dynamic) {
					isInvalid = true;
					continue;
				}
			}
			var out = kind.detect(path, json);
			if (out != null) return out;
		}
		//
		return super.detect(path, json);
	}
	override public function create(name:String, path:String, data:Dynamic, nav:GmlFileNav):GmlFile {
		var json:YyBase;
		if (data != null) {
			json = data;
		} else try {
			json = FileWrap.readYyFileSync(path);
		} catch (x:Dynamic) {
			json = null;
		}
		var kind = json != null ? tools.JsTools.or(json.resourceType, json.modelName) : "<unknown>";
		var opt:Int;
		var dunno = 'GMEdit doesn\'t know how to open YY type $kind.';
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
