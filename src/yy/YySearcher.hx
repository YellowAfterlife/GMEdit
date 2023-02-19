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
import yy.YyTimeline;

/**
 * ...
 * @author YellowAfterlife
 */
class YySearcher {
	var queue:Array<{ fn:Any->Void, arg:Any }> = [];
	var count = 0;
	static inline var maxCount = 16;
	var done:Void->Void;
	function new(done:Void->Void = null) {
		this.done = done;
	}
	function procSync<T>(arg:T, fn:T->Void):Void {
		count++;
		fn(arg);
	}
	function procNext() {
		count--;
		var pair = queue.shift();
		if (pair != null) {
			procSync(pair.arg, pair.fn);
		} else if (count <= 0) done();
	}
	function proc<T>(arg:T, fn:T->Void):Void {
		if (count < maxCount) {
			procSync(arg, fn);
		} else queue.push({ fn: cast fn, arg: arg });
	}
	
	public static function run(
		_project:Project, fn:ProjectSearcher, done:Void->Void, opt:GlobalSearchOpt
	):Void {
		var ctx = new YySearcher(done);
		inline function next():Void {
			ctx.procNext();
		}
		
		var yyProject:YyProject = _project.readYyFileSync(_project.name);
		var scriptLambdas = _project.properties.lambdaMode == Scripts;
		var rxName = Project.rxName;
		
		function addError(s:String) {
			if (opt.errors != null) {
				opt.errors += "\n" + s;
			} else opt.errors = s;
		}
		var v22 = yyProject.resourceType != "GMProject";
		for (resPair in yyProject.resources) {
			var _resName:String, _resPath:RelPath, _resFull:String, _resType:String;
			if (v22) {
				var resVal = resPair.Value;
				_resPath = resVal.resourcePath;
				_resType = resVal.resourceType;
				_resName = null;
			} else {
				_resPath = resPair.id.path;
				_resType = _project.yyResourceTypes[resPair.id.name];
			}
			_resFull = _project.fullPath(_resPath);
			inline function ensureName():Void {
				if (v22) {
					_resName = rxName.replace(_resPath, "$1");
				} else _resName = resPair.id.name;
			}
			inline function packResCtx() {
				return {
					project: _project,
					resName: _resName,
					resPath: _resPath,
					resFull: _resFull,
				};
			}
			switch (_resType) {
				case "GMScript": if (opt.checkScripts) {
					ensureName();
					if (!scriptLambdas
						|| !opt.expandLambdas
						|| !NativeString.startsWith(_resName, GmlExtLambda.lfPrefix)
					) ctx.proc(packResCtx(), function(resCtx) {
						var gmlPath = Path.withExtension(resCtx.resPath, "gml");
						var gmlFull = Path.withExtension(resCtx.resFull, "gml");
						resCtx.project.readTextFile(gmlPath, function(error, code) {
							if (error == null) {
								var gml1 = fn(resCtx.resName, gmlFull, code);
								if (gml1 != null && gml1 != code) {
									resCtx.project.writeTextFileSync(gmlPath, gml1);
								}
							} else Main.console.warn(error);
							next();
						});
					});
				};
				case "GMObject": if (opt.checkObjects) {
					ensureName();
					ctx.proc(packResCtx(), function(resCtx) {
						var resPath = resCtx.resPath;
						resCtx.project.readYyFile(resPath, function(error, obj:YyObject) {
							if (error == null) try {
								var code = obj.getCode(resPath);
								var gml1 = fn(resCtx.resName, resCtx.resFull, code);
								if (gml1 != null && gml1 != code) {
									if (obj.setCode(resPath, gml1)) {
										resCtx.project.writeYyFileSync(resPath, obj);
									} else addError("Failed to modify " + resCtx.resName
										+ ":\n" + YyObject.errorText);
								}
							} catch (x:Dynamic) {
								addError("Failed to modify " + resCtx.resName + ":\n" + x);
							} else Main.console.warn(error);
							next();
						});
					});
				};
				case "GMTimeline": if (opt.checkTimelines) {
					ensureName();
					ctx.proc(packResCtx(), function(resCtx) {
						resCtx.project.readYyFile(resCtx.resPath, function(error, _tl:YyTimelineImpl) {
							var tl:YyTimeline = _tl;
							if (error == null) try {
								var code = tl.getCode(resCtx.resFull);
								var gml1 = fn(resCtx.resName, resCtx.resFull, code);
								if (gml1 != null && gml1 != code) {
									if (tl.setCode(resCtx.resPath, gml1)) {
										resCtx.project.writeYyFileSync(resCtx.resPath, tl);
									} else addError("Failed to modify " + resCtx.resName
										+ ":\n" + YyObject.errorText);
								}
							} catch (x:Dynamic) {
								addError("Failed to modify " + resCtx.resName + ":\n" + x);
							} else Main.console.warn(error);
							next();
						});
					});
				};
				case "GMShader": if (opt.checkShaders) {
					ensureName();
					inline function procShader(ext:String, type:String) {
						ctx.proc({
							project: _project,
							resName: _resName + '($type)',
							shPath: Path.withExtension(_resPath, ext),
							shFull: Path.withExtension(_resFull, ext),
						}, function(shCtx) {
							shCtx.project.readTextFile(shCtx.shPath, function(err, code) {
								if (err == null) {
									var gml1 = fn(shCtx.resName, shCtx.shFull, code);
									if (gml1 != null && gml1 != code) {
										shCtx.project.writeTextFileSync(shCtx.shPath, gml1);
									}
								} else Main.console.warn(err);
								next();
							});
						});
					}
					procShader("fsh", "fragment");
					procShader("vsh", "vertex");
				};
				case "GMExtension": if (opt.checkExtensions) {
					ensureName();
					if (opt.expandLambdas && _resName == GmlExtLambda.extensionName) continue;
					ctx.proc(packResCtx(), function(resCtx) resCtx.project.readYyFile(resCtx.resPath,
					function(err, ext:YyExtension) {
						if (err != null) {
							Main.console.warn(err);
							next();
							return;
						}
						var extDir = Path.directory(resCtx.resPath);
						var extDirFull = Path.directory(resCtx.resFull);
						for (file in ext.files) if (
							tools.PathTools.ptExt(file.filename) == "gml"
						) ctx.proc({
							project: resCtx.project,
							fileName: file.filename,
							filePath: Path.join([extDir, file.filename]),
							fileFull: Path.join([extDirFull, file.filename]),
						}, function(extCtx) {
							var fileName = extCtx.fileName;
							var filePath = extCtx.filePath;
							extCtx.project.readTextFile(filePath, function(err, code) {
								if (err != null) {
									Main.console.warn(err);
									next();
									return;
								}
								var gml1 = fn(fileName, extCtx.fileFull, code);
								if (gml1 != null && gml1 != code) {
									extCtx.project.writeTextFileSync(filePath, gml1);
								}
								next();
							});
						});
						next();
					}));
				};
				case "GMRoom": if (opt.checkRooms) {
					ensureName();
					ctx.proc(packResCtx(), function(resCtx) {
						var rccName = "roomCreationCodes(" + resCtx.resName + ")";
						var rccPath = Path.directory(resCtx.resPath) + "\\RoomCreationCode.gml";
						if (resCtx.project.existsSync(rccPath)) {
							resCtx.project.readTextFile(rccPath, function(error, code) {
								if (error == null) {
									var gml1 = fn(rccName, rccPath, code);
									if (gml1 != null && gml1 != code) {
										FileWrap.writeTextFileSync(rccPath, gml1);
									}
								} else Main.console.warn(error);
								next();
							});
						} else next();
					});
				};
			} // switch (can continue)
		} // for
		if (ctx.count == 0 && ctx.queue.length == 0) done();
	}
}
