package shaders;
import ace.AceWrap;
import ace.extern.*;
import electron.FileSystem;
import electron.FileWrap;
import gml.GmlFuncDoc;
import parsers.GmlParseAPI;
import tools.Dictionary;
using tools.ERegTools;

/**
 * ...
 * @author YellowAfterlife
 */
class ShaderAPI {
	//
	public static var glslKind:Dictionary<String>;
	public static var glslDoc:Dictionary<GmlFuncDoc>;
	public static var glslComp:AceAutoCompleteItems;
	//
	public static var hlslKind:Dictionary<String>;
	public static var hlslDoc:Dictionary<GmlFuncDoc>;
	public static var hlslComp:AceAutoCompleteItems;
	//
	public static function init() {
		for (iter in 0 ... 2) {
			var name = iter > 0 ? "hlsl" : "glsl";
			var kind = new Dictionary<String>();
			var doc = new Dictionary<GmlFuncDoc>();
			var comp = new AceAutoCompleteItems();
			//
			function loadAPI(path_names:String, path_keywords:String) {
				FileSystem.readTextFile(path_names, function(e, defs) {
					GmlParseAPI.loadStd(defs, {
						kind: kind, doc: doc, comp: comp,
						kindPrefix: name
					});

					FileSystem.readTextFile(path_keywords, function(e, d) {
						GmlParseAPI.loadStd(d, {
							kind: kind, doc: doc, comp: comp,
							kindPrefix: name
						});
						
						~/(\w+)/gm.each(d, function(rx:EReg) {
							kind.set(rx.matched(1), "keyword");
						});
						for (compItem in comp) {
							var kindGet = kind.get(compItem.name);
							if (kind.get(compItem.name) == "keyword") {
								compItem.meta = "keyword";
							}
						}
					});
				});
			}
			//
			loadAPI(Main.relPath('api/shaders/${name}_names'), Main.relPath('api/shaders/keywords_$name.txt'));
			// custom syntax
			if (FileSystem.canSync) {
				var xdir = FileWrap.userPath + "/api/shaders";

				var xsearch:String->Void = null;
				xsearch = function(xdir:String) {
					for (xrel in FileSystem.readdirSync(xdir)) {
						var xfull = xdir + "/" + xrel;
						if (FileSystem.statSync(xfull).isDirectory()) {
							xsearch(xfull);
							continue;
						}
						if (xrel == "glsl_names") {
							loadAPI(xfull, '${xdir}/keywords_$name.txt');
							continue;
						}
					}
				}
				
				if (FileSystem.existsSync(xdir))
					xsearch(xdir);
			}
			//
			if (iter == 0) {
				glslKind = kind;
				glslComp = comp;
				glslDoc = doc;
			} else {
				hlslKind = kind;
				hlslComp = comp;
				hlslDoc = doc;
			}
		}
	}
}
