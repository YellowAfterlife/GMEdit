package gml.file;
import electron.FileSystem;
import electron.Menu;
import file.FileKind;
import file.kind.gml.KGmlScript;
import haxe.io.Path;
import ui.Preferences;
using tools.NativeString;
using tools.NativeArray;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFileBackup {
	public static var menu:Menu;
	static function getPath(file:GmlFile) {
		var path = file.path;
		if (path == null) return null;
		path = Path.normalize(path);
		var dir = Path.normalize(Project.current.dir);
		if (!path.startsWith(dir)) return null;
		return path.insert(dir.length, "/#backups");
	}
	static inline function indexPath(path:String, i:Int) {
		return path + ".backup" + i;
	}
	public static function save(file:GmlFile, code:String) {
		#if lwedit
		return;
		#end
		if (!FileSystem.canSync) return;
		var num = Preferences.current.backupCount[Project.current.version.name];
		if (num == null || num <= 0) return;
		//
		var path = getPath(file);
		if (path == null) return;
		if (!Path.isAbsolute(path)) return;
		//
		try {
			var i = num - 1;
			var gap = 0;
			while (gap < 4) {
				var bkp = indexPath(path, i);
				if (FileSystem.existsSync(bkp)) {
					FileSystem.unlinkSync(bkp);
					gap = 0;
				} else gap += 1;
				i += 1;
			}
			//
			i = num - 1;
			while (i >= 0) {
				var s1 = indexPath(path, i);
				i -= 1;
				var s0 = indexPath(path, i);
				if (FileSystem.existsSync(s0)) {
					FileSystem.renameSync(s0, s1);
				}
			}
			//
			var pjDir = Path.normalize(Project.current.dir);
			var dirs = Path.directory(path).substring(pjDir.length + 1).split("/");
			var dirp = pjDir;
			for (dir in dirs) {
				dirp += "/" + dir;
				if (!FileSystem.existsSync(dirp)) {
					FileSystem.mkdirSync(dirp);
				}
			}
			//
			code = "// " + Date.now().toString() + "\r\n" + code;
			FileSystem.writeFileSync(indexPath(path, 0), code);
		} catch (e:Dynamic) {
			Main.console.log("Error making backup: ", e);
		}
	}
	static function load(name:String, path:String, kind:FileKind) {
		if (GmlFileKindTools.isGML(kind)) kind = KGmlScript.inst;
		var file = new GmlFile(name, path, kind);
		file.path = null; // prevent from being able to "save" a backup
		GmlFile.openTab(file);
	}
	public static function updateMenu(file:GmlFile):Bool {
		if (!FileSystem.canSync) return null;
		var path = getPath(file);
		// can't make backups for files without paths
		if (path == null) return null;
		// and can't make backups for virtual files either
		if (!Path.isAbsolute(path)) return null;
		menu.clear();
		//
		var name = file.name;
		var kind = file.kind;
		file = null;
		//
		try {
			var i = 0, gap = 0;
			while (gap < 4) {
				var bkp = indexPath(path, i);
				i += 1;
				if (FileSystem.existsSync(bkp)) {
					var t = FileSystem.statSync(bkp).mtime;
					menu.append(new MenuItem({
						label: i + ": " + t.toString(),
						click: function() load(name + " <backup>", bkp, kind)
					}));
					gap = 0;
				} else gap += 1;
			}
		} catch (_:Dynamic) {
			return false;
		}
		return true;
	}
	public static function init(){
		menu = new Menu();
	}
}
