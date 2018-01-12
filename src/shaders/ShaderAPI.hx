package shaders;
import ace.AceWrap;
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
			var kws = FileSystem.readTextFileSync(Main.relPath('api/shaders/keywords_$name.txt'));
			~/(\w+)/gm.each(kws, function(rx:EReg) {
				kind.set(rx.matched(1), "keyword");
			});
			//
			var defs = FileSystem.readTextFileSync(Main.relPath('api/shaders/${name}_names'));
			GmlParseAPI.loadStd(defs, {
				kind: kind, doc: doc, comp: comp,
				kindPrefix: name
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
