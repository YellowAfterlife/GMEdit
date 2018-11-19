package gmx;
import electron.FileWrap;
import gml.Project;
import haxe.io.Path;
import js.Error;
import parsers.GmlReader;
import tools.StringBuilder;
import ui.GlobalSearch;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxSearcher {
	public static function run(
		pj:Project, fn:ProjectSearcher, done:Void->Void, opt:GlobalSearchOpt
	):Void {
		var isRepl = opt.replaceBy != null;
		var pjDir = pj.dir;
		var pjGmx = FileWrap.readGmxFileSync(pj.path);
		var rxName = GmxLoader.rxAssetName;
		var filesLeft = 1;
		inline function next():Void {
			if (--filesLeft <= 0) done();
		}
		function addError(s:String) {
			if (opt.errors != null) {
				opt.errors += "\n" + s;
			} else opt.errors = s;
		}
		function findrec(node:SfGmx, one:String) {
			if (node.name == one) {
				var name = rxName.replace(node.text, "$1");
				var full = Path.join([pjDir, node.text]);
				switch (one) {
					case "object": {
						full += '.$one.gmx';
						filesLeft += 1;
						FileWrap.readTextFile(full, function(err:Error, xml:String) {
							if (err == null) {
								var gmx = SfGmx.parse(xml);
								var gml0 = GmxObject.getCode(gmx);
								if (gml0 != null) {
									var gml1 = fn(name, full, gml0);
									if (gml1 != null && gml1 != gml0) {
										if (GmxObject.setCode(gmx, gml1)) {
											FileWrap.writeTextFileSync(full, gmx.toGmxString());
										} else {
											addError("Failed to modify " + name
												+ ":\n" + GmxObject.errorText);
										}
									}
								}
							}
							next();
						});
					};
					case "timeline": {
						full += '.$one.gmx';
						filesLeft += 1;
						FileWrap.readTextFile(full, function(err:Error, xml:String) {
							if (err == null) {
								var gmx = SfGmx.parse(xml);
								var gml0 = GmxTimeline.getCode(gmx);
								if (gml0 != null) {
									var gml1 = fn(name, full, gml0);
									if (gml1 != null && gml1 != gml0) {
										if (GmxTimeline.setCode(gmx, gml1)) {
											FileWrap.writeTextFileSync(full, gmx.toGmxString());
										} else {
											addError("Failed to modify " + name
												+ ":\n" + GmxTimeline.errorText);
										}
									}
								}
							}
							next();
						});
					};
					case "script", "shader": {
						filesLeft += 1;
						FileWrap.readTextFile(full, function(err:Error, code:String) {
							if (err == null) {
								var gml1 = fn(name, full, code);
								if (gml1 != null && gml1 != code) {
									FileWrap.writeTextFileSync(full, gml1);
								}
							}
							next();
						});
					};
				}
			} else {
				for (child in node.children) findrec(child, one);
			}
		}
		if (opt.checkScripts) for (q in pjGmx.findAll("scripts")) findrec(q, "script");
		if (opt.checkObjects) for (q in pjGmx.findAll("objects")) findrec(q, "object");
		if (opt.checkTimelines) for (q in pjGmx.findAll("timelines")) findrec(q, "timeline");
		if (opt.checkShaders) for (q in pjGmx.findAll("shaders")) findrec(q, "shader");
		if (opt.checkExtensions) {
			for (q in pjGmx.findAll("NewExtensions")) for (extNode in q.findAll("extension")) {
				var extPath = extNode.text + ".extension.gmx";
				if (opt.expandLambdas && extNode.text == parsers.GmlExtLambda.extensionName) continue;
				filesLeft += 1;
				pj.readGmxFile(extPath, function(extError, extGmx:SfGmx) {
					if (extError == null) {
						for (extFiles in extGmx.findAll("files"))
						for (extFile in extFiles.findAll("file")) {
							var extFileName = extFile.findText("filename");
							if (Path.extension(extFileName).toLowerCase() != "gml") continue;
							var extFilePath = Path.join([extNode.text, extFileName]);
							filesLeft += 1;
							pj.readTextFile(extFilePath, function(err, code) {
								if (err == null) {
									var gml1 = fn(extFilePath, extFilePath, code);
									if (gml1 != null && gml1 != code) {
										pj.writeTextFileSync(extFilePath, gml1);
									}
								}
								next();
							});
						}
					}
					next();
				});
			}
		}
		//
		function findMcr(name:String, full:String, pjGmx:SfGmx) {
			function procMcr(gmx:SfGmx) {
				var notePath = GmxProject.getNotePath(full);
				var notes = FileWrap.existsSync(notePath)
					? new GmlReader(FileWrap.readTextFileSync(notePath)) : null;
				var gml0 = GmxProject.getMacroCode(gmx, notes, pjGmx == null);
				var gml1 = fn(name, full, gml0);
				if (gml1 != null && gml1 != gml0) {
					var notes1 = new StringBuilder();
					if (GmxProject.setMacroCode(gmx, gml1, notes1, pjGmx == null)) {
						if (notes1.length > 0) {
							FileWrap.writeTextFileSync(notePath, notes1.toString());
						} else if (FileWrap.existsSync(notePath)) {
							FileWrap.unlinkSync(notePath);
						}
						FileWrap.writeTextFileSync(full, gmx.toGmxString());
					} else {
						addError("Failed to modify " + name
							+ ":\n" + GmxTimeline.errorText);
					}
				}
			}
			//
			if (pjGmx == null) {
				filesLeft += 1;
				FileWrap.readTextFile(full, function(err:Error, xml:String) {
					if (err == null) procMcr(SfGmx.parse(xml));
					next();
				});
			} else procMcr(pjGmx);
		}
		if (opt.checkMacros) {
			for (configs in pjGmx.findAll("Configs"))
			for (config in configs.findAll("Config")) {
				var configPath = config.text;
				var configName = rxName.replace(configPath, "$1");
				var configFull = Path.join([pjDir, configPath + ".config.gmx"]);
				findMcr(configName, configFull, null);
			}
		}
		findMcr(GmxLoader.allConfigs, pj.path, pjGmx);
		//
		next();
	}
}
