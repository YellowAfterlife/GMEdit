package gml.file;
import file.FileKind;
import file.FileKindDetect;
import file.kind.*;
import file.kind.misc.KExtern;
import haxe.io.Path;
import yy.*;
import electron.*;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFileKindTools {
	public static function isGML(kind:FileKind) {
		return Std.is(kind, KGml);
	}
	public static function detect(path:String):FileKindDetect {
		var ext = Path.extension(path).toLowerCase();
		var kinds = FileKind.map[ext];
		if (kinds != null) for (kind in kinds) {
			var out = kind.detect(path, null);
			if (out != null) return out;
		}
		return { kind: KExtern.inst, data: null };
	}
}
