package shaders;
import ace.AceWrap;
import ace.extern.*;
import electron.FileSystem;
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
			FileSystem.readTextFile(Main.relPath('api/shaders/keywords_$name.txt'), function(e, d) {
				~/(\w+)/gm.each(d, function(rx:EReg) {
					kind.set(rx.matched(1), "keyword");
				});
			});
			//
			FileSystem.readTextFile(Main.relPath('api/shaders/${name}_names'), function(e, defs) {
				GmlParseAPI.loadStd(defs, {
					kind: kind, doc: doc, comp: comp,
					kindPrefix: name
				});
			});
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
