package yy.zip;
import yy.zip.YyZip;
import gml.GmlVersion;
using tools.PathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class YyZipTools {
	/** Figures out the project file in a set */
	public static function locateMain(entries:Array<YyZipFile>):String {
		var main = null;
		var mainDepth = 0;
		for (entry in entries) {
			var path = entry.path;
			var pair = path.ptDetectProject();
			if (pair.version != GmlVersion.none) {
				var depth = path.ptDepth();
				if (main == null || depth < mainDepth) {
					// top-level files are preferred
					main = path;
					mainDepth = depth;
				}
			}
		}
		return main;
	}
}