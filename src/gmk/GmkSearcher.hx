package gmk;
import electron.FileWrap;
import gmk.GmkObject;
import gml.Project;
import gmx.SfGmx;
import haxe.io.Path;
import js.lib.Error;
import parsers.GmlReader;
import tools.StringBuilder;
import ui.GlobalSearch;
import tools.Aliases;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmkSearcher {
	public static function run(
		project:Project, fn:ProjectSearcher, done:Void->Void, opt:GlobalSearchOpt
	):Void {
		var pjDir = project.dir;
		var pjGmx = FileWrap.readGmxFileSync(project.path);
		var filesLeft = 1;
		inline function next():Void {
			if (--filesLeft <= 0) done();
		}
		function addError(s:String) {
			if (opt.errors != null) {
				opt.errors += "\n" + s;
			} else opt.errors = s;
		}
		//
		function seekRec(dir:FullPath, kind:String, suffix:String):Void {
			var rxml = '$dir/_resources.list.xml';
			if (!project.existsSync(rxml)) return;
			var xml = project.readGmxFileSync(rxml);
			for (item in xml.children) {
				var name = item.get("name");
				var fname = item.get("filename");
				if (fname == null) fname = name;
				var rel = '$dir/$fname';
				if (item.get("type") == "GROUP") {
					seekRec(rel, kind, suffix);
					continue;
				}
				rel += suffix;
				switch (kind) {
					case "script": {
						filesLeft += 1;
						project.readTextFile(rel, function(e, gml0) {
							if (e != null) { next(); return; }
							var gml1 = fn(name, rel, gml0);
							if (gml1 != null && gml1 != gml0) {
								project.writeTextFileSync(rel, gml1);
							}
							next();
						});
					};
					case "object": {
						filesLeft += 1;
						project.readGmxFile(rel, function(e, xml) {
							if (xml == null) { next(); return; }
							var gml0 = GmkObject.getCode(xml, rel);
							if (gml0 == null) { next(); return; }
							var gml1 = fn(name, rel, gml0);
							if (gml1 != null && gml1 != gml0) {
								if (GmkObject.setCode(xml, rel, gml1)) {
									project.writeGmkSplitFileSync(rel, xml);
								} else {
									addError("Failed to modify " + name
										+ ":\n" + GmkObject.errorText);
								}
							}
							next();
						});
					};
				}
			}
		}
		function seekRecRoot(dir:FullPath, kind:String, suffix:String = ""):Void {
			seekRec(dir, kind, suffix);
		}
		var baseDir = project.dir;
		if (opt.checkScripts) seekRecRoot("Scripts", "script", ".gml");
		if (opt.checkObjects) seekRecRoot("Objects", "object", ".xml");
		//
		next();
	}
}