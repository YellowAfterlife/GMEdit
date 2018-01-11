package gmx;
import electron.FileSystem;
import gml.Project;
import haxe.io.Path;
import js.Error;
import ui.GlobalSearch;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxSearcher {
	public static function run(
		pj:Project, fn:ProjectSearcher, done:Void->Void, ?opt:GlobalSearchOpt
	):Void {
		var isRepl = opt.replaceBy != null;
		var pjDir = pj.dir;
		var pjGmx = FileSystem.readGmxFileSync(pj.path);
		var rxName = ~/^.+[\/\\](\w+)(?:\.[\w.]+)?$/g;
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
						FileSystem.readTextFile(full, function(err:Error, xml:String) {
							if (err == null) {
								var gmx = SfGmx.parse(xml);
								var gml0 = GmxObject.getCode(gmx);
								if (gml0 != null) {
									var gml1 = fn(name, full, gml0);
									if (gml1 != null && gml1 != gml0) {
										if (GmxObject.setCode(gmx, gml1)) {
											FileSystem.writeFileSync(full, gmx.toGmxString());
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
						FileSystem.readTextFile(full, function(err:Error, xml:String) {
							if (err == null) {
								var gmx = SfGmx.parse(xml);
								var gml0 = GmxTimeline.getCode(gmx);
								if (gml0 != null) {
									var gml1 = fn(name, full, gml0);
									if (gml1 != null && gml1 != gml0) {
										if (GmxTimeline.setCode(gmx, gml1)) {
											FileSystem.writeFileSync(full, gmx.toGmxString());
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
					case "script": {
						filesLeft += 1;
						FileSystem.readTextFile(full, function(err:Error, code:String) {
							if (err == null) {
								var gml1 = fn(name, full, code);
								if (gml1 != null && gml1 != code) {
									FileSystem.writeFileSync(full, gml1);
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
		if (opt == null || opt.checkScripts) for (q in pjGmx.findAll("scripts")) findrec(q, "script");
		if (opt == null || opt.checkObjects) for (q in pjGmx.findAll("objects")) findrec(q, "object");
		if (opt == null || opt.checkTimelines) for (q in pjGmx.findAll("timelines")) findrec(q, "timeline");
		next();
	}
}
