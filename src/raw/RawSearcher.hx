package raw;
import gml.Project;
import haxe.io.Path;
import ui.GlobalSearch;
using tools.PathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class RawSearcher {
	public static function run(
		pj:Project, fn:ProjectSearcher, done:Void->Void, opt:GlobalSearchOpt
	):Void {
		//
		var filesLeft = 1;
		inline function next():Void {
			if (--filesLeft <= 0) done();
		}
		//
		function searchRec(dirPath:String):Void {
			for (pair in pj.readdirSync(dirPath)) {
				var relPath = pair.relPath;
				var fullPath = pair.fullPath;
				if (pair.isDirectory) {
					searchRec(relPath);
				} else if (fullPath.ptExt() == "gml") {
					filesLeft += 1;
					pj.readTextFile(relPath, function(err, code) {
						if (err == null) {
							var name:String;
							if (pj.version.config.indexingMode == Local) {
								name = relPath;
							} else name = relPath.ptName();
							var gml1 = fn(name, relPath, code);
							if (gml1 != null && gml1 != code) {
								pj.writeTextFileSync(relPath, gml1);
							}
						}
						next();
					});
				}
			}
		}
		searchRec("");
		next();
	}
}
