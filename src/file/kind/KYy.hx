package file.kind;

import electron.FileWrap;
import file.FileKind;
import file.FileKindDetect;
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
		var json:YyBase = data != null ? data : FileWrap.readJsonFileSync(path);
		var kinds = map[json.modelName];
		if (kinds != null) for (kind in kinds) {
			var out = kind.detect(path, json);
			if (out != null) return out;
		}
		return null;
	}
}
