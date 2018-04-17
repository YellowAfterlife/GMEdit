package yy;
import electron.FileSystem;
import electron.FileWrap;
import gml.Project;
import haxe.io.Path;
import js.Error;
import ui.GlobalSearch;

/**
 * ...
 * @author YellowAfterlife
 */
class YySearcher {
	public static function run(
		pj:Project, fn:ProjectSearcher, done:Void->Void, ?opt:GlobalSearchOpt
	):Void {
		var yyProject:YyProject = pj.readJsonFileSync(pj.name);
		var rxName = Project.rxName;
		var filesLeft = 1;
		inline function next():Void {
			if (--filesLeft <= 0) done();
		}
		function addError(s:String) {
			if (opt.errors != null) {
				opt.errors += "\n" + s;
			} else opt.errors = s;
		}
		for (resPair in yyProject.resources) {
			var res = resPair.Value;
			var resName:String, resFull:String;
			switch (res.resourceType) {
				case "GMScript": if (opt == null || opt.checkScripts) {
					resName = rxName.replace(res.resourcePath, "$1");
					resFull = Path.withoutExtension(res.resourcePath) + ".gml";
					filesLeft += 1;
					pj.readTextFile(resFull, function(error, code) {
						if (error == null) {
							var gml1 = fn(resName, resFull, code);
							if (gml1 != null && gml1 != code) {
								FileWrap.writeTextFileSync(resFull, gml1);
							}
						}
						next();
					});
				};
				case "GMObject": if (opt == null || opt.checkObjects) {
					resName = rxName.replace(res.resourcePath, "$1");
					resFull = res.resourcePath;
					filesLeft += 1;
					pj.readTextFile(resFull, function(error, data) {
						if (error == null) try {
							var resDir = Path.directory(resFull);
							var obj:YyObject = haxe.Json.parse(data);
							var code = obj.getCode(resFull);
							var gml1 = fn(resName, resFull, code);
							if (gml1 != null && gml1 != code) {
								if (obj.setCode(resFull, gml1)) {
									// OK!
								} else addError("Failed to modify " + resName
									+ ":\n" + YyObject.errorText);
							}
						} catch (_:Dynamic) { };
						next();
					});
				};
				case "GMTimeline": if (opt == null || opt.checkObjects) {
					resName = rxName.replace(res.resourcePath, "$1");
					resFull = res.resourcePath;
					filesLeft += 1;
					pj.readTextFile(resFull, function(error, data) {
						if (error == null) try {
							var resDir = Path.directory(resFull);
							var tl:YyTimeline = haxe.Json.parse(data);
							var code = tl.getCode(resFull);
							var gml1 = fn(resName, resFull, code);
							if (gml1 != null && gml1 != code) {
								if (tl.setCode(resFull, gml1)) {
									// OK!
								} else addError("Failed to modify " + resName
									+ ":\n" + YyObject.errorText);
							}
						} catch (_:Dynamic) { };
						next();
					});
				};
			}
		}
		next();
	}
}
