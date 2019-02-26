package file.kind;

import file.FileKind;
import file.FileKindDetect;
import haxe.io.Path;
import tools.Dictionary;

/**
 * GMX sub-kind resolver
 * @author YellowAfterlife
 */
class KGmx extends FileKind {
	public static var inst:KGmx = new KGmx();
	private static var map:Dictionary<Array<FileKind>> = new Dictionary();
	public static function register(subExt:String, file:FileKind):Void {
		var arr = map[subExt];
		if (arr == null) {
			arr = [];
			map.set(subExt, arr);
		}
		arr.unshift(file);
	}
	override public function detect(path:String, data:Dynamic):FileKindDetect {
		var ext = Path.extension(Path.withoutExtension(path)).toLowerCase();
		var kinds = map[ext];
		if (kinds != null) for (kind in kinds) {
			var out = kind.detect(path, data);
			if (out != null) return out;
		}
		return null;
	}
}
