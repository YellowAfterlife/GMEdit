package gml.file;
import file.FileKind;
import file.FileKindDetect;
import file.kind.*;
import file.kind.misc.KExtern;
import haxe.io.Path;
import file.kind.gml.*;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFileKindTools {
	public static function isGML(kind:FileKind) {
		return Std.is(kind, KGml);
	}
	/** Returns whether top-level `function name()` should change context */
	public static inline function functionsAreGlobal(kind:FileKind) {
		return Std.is(kind, KGmlScript) && (cast kind:KGmlScript).isScript;
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
