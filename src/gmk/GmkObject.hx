package gmk;
import electron.FileSystem;
import electron.FileWrap;
import gml.GmlVersion;
import gmx.SfGmx;
import haxe.io.Path;
import tools.Aliases;

/**
 * ...
 * @author YellowAfterlife
 */
class GmkObject {
	public static var errorText:String = null;
	public static function getCode(gmx:SfGmx, path:String):GmlCode {
		errorText = null;
		// obj_some.xml => obj_some.events
		var dir = Path.withExtension(path, "events");
		if (!FileWrap.existsSync(dir)) return "";
		var out = "";
		var errors = "";
		var events:Array<SfGmx> = [];
		for (entry in FileWrap.readdirSync(dir)) {
			events.push(FileWrap.readGmxFileSync(entry.relPath));
		}
		
		events.sort(GmkEvent.compare);
		
		for (event in events) {
			if (out != "") out += "\n";
			var name = GmkEvent.toStringGmk(event);
			out += "#event " + name;
			if (GmkEvent.isEmpty(event)) continue;
			var code = GmkEvent.getCode(event);
			if (code != null) {
				var pair = parsers.GmlHeader.parse(code, GmlVersion.v1);
				if (pair.name != null) out += pair.name;
				out += "\n" + pair.code;
			} else {
				errors += "Unreadable action in " + name + ":\n";
				errors += GmkAction.errorText + "\n";
			}
		}
		if (errors != "") {
			errorText = errors;
			return null;
		} else return tools.NativeString.trimTrailRn(out);
	}
	public static function setCode(gmx:SfGmx, path:String, code:GmlCode):Bool {
		errorText = "Changing GMK objects is not supported.";
		return false;
	}
}