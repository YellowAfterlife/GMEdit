package yy;
import electron.FileSystem;
import electron.FileWrap;
import gml.Project;
import haxe.io.Path;
import js.lib.Error;
import synext.GmlExtLambda;
import tools.Aliases;
import tools.NativeString;
import ui.GlobalSearch;

/**
 * ...
 * @author YellowAfterlife
 */
class YySearcher {
	public static function run(
		pj:Project, fn:ProjectSearcher, done:Void->Void, opt:GlobalSearchOpt
	):Void {
		var yyProject:YyProject = pj.readYyFileSync(pj.name);
		var scriptLambdas = pj.properties.lambdaMode == Scripts;
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
		var v22 = yyProject.resourceType != "GMProject";
		for (resPair in yyProject.resources) {
			var resName:String, resPath:RelPath, resFull:String, resType:String;
			if (v22) {
				var resVal = resPair.Value;
				resPath = resVal.resourcePath;
				resType = resVal.resourceType;
				resName = null;
			} else {
				resPath = resPair.id.path;
				resType = pj.yyResourceTypes[resPair.id.name];
			}
			resFull = pj.fullPath(resPath);
			inline function ensureName():Void {
				if (v22) {
					resName = rxName.replace(resPath, "$1");
				} else resName = resPair.id.name;
			}
			switch (resType) {
				case "GMScript": if (opt.checkScripts) {
					ensureName();
					if (!scriptLambdas
						|| !opt.expandLambdas
						|| !NativeString.startsWith(resName, GmlExtLambda.lfPrefix)
					) {
						filesLeft += 1;
						var gmlPath = Path.withExtension(resPath, "gml");
						pj.readTextFile(gmlPath, function(error, code) {
							if (error == null) {
								var gml1 = fn(resName, resFull, code);
								if (gml1 != null && gml1 != code) {
									pj.writeTextFileSync(gmlPath, gml1);
								}
							} else Main.console.warn(error);
							next();
						});
					}
				};
				case "GMObject": if (opt.checkObjects) {
					ensureName();
					filesLeft += 1;
					pj.readTextFile(resPath, function(error, data) {
						if (error == null) try {
							var obj:YyObject = YyJson.parse(data, !v22);
							var code = obj.getCode(resFull);
							var gml1 = fn(resName, resFull, code);
							if (gml1 != null && gml1 != code) {
								if (obj.setCode(resFull, gml1)) {
									// OK!
								} else addError("Failed to modify " + resName
									+ ":\n" + YyObject.errorText);
							}
						} catch (x:Dynamic) {
							Main.console.warn(x);
						} else Main.console.warn(error);
						next();
					});
				};
				case "GMTimeline": if (opt.checkObjects) {
					ensureName();
					filesLeft += 1;
					pj.readTextFile(resPath, function(error, data) {
						if (error == null) try {
							var tl:YyTimeline = YyJson.parse(data, !v22);
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
				case "GMShader": if (opt.checkShaders) {
					ensureName();
					var shPath:String;
					inline function procShader(ext:String, type:String) {
						shPath = Path.withExtension(resPath, ext);
						pj.readTextFile(shPath, function(err, code) {
							if (err == null) {
								var gml1 = fn(resName + '($type)', shPath, code);
								if (gml1 != null && gml1 != code) {
									pj.writeTextFileSync(shPath, gml1);
								}
							} else Main.console.warn(err);
							next();
						});
					}
					filesLeft += 2;
					procShader("fsh", "fragment");
					procShader("vsh", "vertex");
				};
				case "GMExtension": if (opt.checkExtensions) {
					ensureName();
					if (opt.expandLambdas && resName == GmlExtLambda.extensionName) continue;
					filesLeft += 1;
					pj.readYyFile(resPath, function(err, ext:YyExtension) {
						if (err != null) {
							Main.console.warn(err);
							next();
							return;
						}
						var extDir = Path.directory(resPath);
						for (file in ext.files) {
							var fileName = file.filename;
							if (Path.extension(fileName).toLowerCase() != "gml") continue;
							var filePath = Path.join([extDir, fileName]);
							filesLeft += 1;
							pj.readTextFile(filePath, function(err, code) {
								if (err != null) {
									Main.console.warn(err);
									next();
									return;
								}
								var gml1 = fn(fileName, filePath, code);
								if (gml1 != null && gml1 != code) {
									pj.writeTextFileSync(filePath, gml1);
								}
								next();
							});
						}
						next();
					});
				};
				case "GMRoom": if (opt.checkRooms) {
					ensureName();
					var rccName = "roomCreationCodes(" + resName + ")";
					var rccPath = Path.directory(resPath) + "\\RoomCreationCode.gml";
					filesLeft += 1;
					pj.readTextFile(rccPath, function(error, code) {
						if (error == null) {
							var gml1 = fn(rccName, rccPath, code);
							if (gml1 != null && gml1 != code) {
								FileWrap.writeTextFileSync(rccPath, gml1);
							}
						} else Main.console.warn(error);
						next();
					});
				};
			} // switch (can continue)
		} // for
		next();
	}
}
