package file.kind.yy;
import electron.FileWrap;
import file.kind.misc.KGLSL;
import file.kind.misc.KHLSL;
import gml.file.GmlFile.GmlFileNav;
import file.kind.KCode;
import gml.file.GmlFile;
import haxe.io.Path;

/**
 * A proxy type that opens both vertex+fragment tabs for editing
 * @author YellowAfterlife
 */
class KYyShader extends FileKind {
	public static var inst:KYyShader = new KYyShader();
	override public function create(name:String, path:String, data:Dynamic, nav:GmlFileNav):GmlFile {
		if (data == null) data = FileWrap.readYyFileSync(path);
		var shKind:FileKind = switch (data.type) {
			case 2, 4: KHLSL.inst;
			default: KGLSL.inst;
		};
		var nav1:GmlFileNav = { kind: shKind };
		if (nav != null) {
			nav1.pos = nav.pos;
			nav1.ctx = nav.ctx;
		}
		var pathNx = Path.withoutExtension(path);
		if (nav != null) switch (nav.def) {
			case "vertex": return GmlFile.open(name + ".vsh", pathNx + ".vsh", nav1);
			case "fragment": return GmlFile.open(name + ".fsh", pathNx + ".fsh", nav1);
		}
		GmlFile.open(name + ".vsh", pathNx + ".vsh", nav1);
		GmlFile.open(name + ".fsh", pathNx + ".fsh", nav1);
		return null;
	}
}
