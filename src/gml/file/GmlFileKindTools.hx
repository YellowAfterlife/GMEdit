package gml.file;
import haxe.io.Path;
import yy.*;
import electron.*;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFileKindTools {
	public static function detect(path:String):{kind:GmlFileKind, data:Null<Dynamic>} {
		var ext = Path.extension(path).toLowerCase();
		var data:Dynamic = null;
		var kind:GmlFileKind;
		switch (ext) {
			case "gml": kind = Normal;
			case "txt": kind = Plain;
			case "js": kind = JavaScript;
			case "shader", "vsh", "fsh": kind = GLSL;
			case "gmx": {
				ext = Path.extension(Path.withoutExtension(path)).toLowerCase();
				kind = switch (ext) {
					case "object": GmxObjectEvents;
					case "project": GmxProjectMacros;
					case "config": GmxConfigMacros;
					case "timeline": GmxTimelineMoments;
					default: Extern;
				}
			};
			case "yy": {
				var json:YyBase = FileSystem.readJsonFileSync(path);
				switch (json.modelName) {
					case "GMObject": {
						data = json;
						kind = YyObjectEvents;
					};
					case "GMShader": {
						data = json;
						kind = YyShader;
					};
					case "GMTimeline": {
						data = json;
						kind = YyTimelineMoments;
					};
					case "GMScript": {
						path = Path.withoutExtension(path) + ".gml";
						kind = Normal;
					};
					default: kind = Extern;
				};
			};
			default: kind = Extern;
		}
		return { kind: kind, data: data };
	}
}
