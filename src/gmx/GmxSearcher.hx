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
		var pjDir = pj.dir;
		var pjGmx = FileSystem.readGmxFileSync(pj.path);
		var rxName = ~/^.+[\/\\](\w+)(?:\.[\w.]+)?$/g;
		var filesLeft = 1;
		inline function next():Void {
			if (--filesLeft <= 0) done();
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
								var code = GmxObject.getCode(SfGmx.parse(xml));
								if (code != null) fn(name, full, code);
							}
							next();
						});
					};
					case "timeline": {
						full += '.$one.gmx';
						filesLeft += 1;
						FileSystem.readTextFile(full, function(err:Error, xml:String) {
							if (err == null) {
								var code = GmxTimeline.getCode(SfGmx.parse(xml));
								if (code != null) fn(name, full, code);
							}
							next();
						});
					};
					case "script": {
						filesLeft += 1;
						FileSystem.readTextFile(full, function(err:Error, code:String) {
							if (err == null) fn(name, full, code);
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
