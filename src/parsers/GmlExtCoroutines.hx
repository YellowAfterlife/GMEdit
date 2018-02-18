package parsers;
import ace.AceWrap;
import gml.GmlAPI;
import js.RegExp;
import tools.Dictionary;
import ui.Preferences;

/**
 * Handles conversion from/to #gmcr magic.
 * @author YellowAfterlife
 */
class GmlExtCoroutines {
	private static var keywordMap0:Dictionary<AceTokenType> = new Dictionary();
	private static var keywordMap1:Dictionary<AceTokenType> = Dictionary.fromKeys(
		["yield", "label", "goto"], "keyword");
	public static var keywordMap:Dictionary<AceTokenType> = keywordMap0;
	public static var enabled:Bool = false;
	public static inline function update(enable:Bool) {
		enabled = enable;
		keywordMap = enable ? keywordMap1 : keywordMap0;
	}
	//
	private static inline var prefix = "/*//!#gmcr";
	private static inline var suffix = "//!#gmcr*/";
	public static function pre(gml:String):String {
		if (!Preferences.current.coroutineMagic) return gml;
		gml = {
			var pos0 = gml.indexOf(prefix);
			if (pos0 < 0) return gml;
			var pos1 = gml.indexOf(suffix);
			if (pos1 < 0) pos1 = gml.length;
			//
			pos0 += prefix.length;
			if (gml.charCodeAt(pos0) == "\r".code) pos0 += 1;
			if (gml.charCodeAt(pos0) == "\n".code) pos0 += 1;
			if (gml.charCodeAt(pos1 - 1) == "\n".code) pos1 -= 1;
			if (gml.charCodeAt(pos1 - 1) == "\r".code) pos1 -= 1;
			//
			gml.substring(pos0, pos1);
		};
		var version = GmlAPI.version;
		var q = new GmlReader(gml);
		var out = "";
		var start = 0;
		inline function flush(till:Int):Void {
			out += q.substring(start, till);
		}
		//
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: {
						flush(q.pos);
						start = ++q.pos;
						while (q.loop) {
							c = q.read();
							if (c == "*".code
								&& q.peek() == "\\".code
								&& q.peek(1) == "/".code
							) {
								flush(q.pos);
								start = ++q.pos;
								q.pos += 1;
								break;
							}
						}
					};
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				default: { };
			}
		}
		flush(q.pos);
		return out;
	}
	public static var errorText:String;
	private static var markRx = new RegExp("^#gmcr", "m");
	public static function post(code:String):String {
		if (!Preferences.current.coroutineMagic) return code;
		if (!markRx.test(code)) return code;
		var found = false;
		var version = GmlAPI.version;
		var q = new GmlReader(code);
		var out = "";
		var start = 0;
		inline function flush(till:Int):Void {
			out += q.substring(start, till);
		}
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: {
						flush(q.pos);
						start = ++q.pos;
						while (q.loop) {
							c = q.read();
							if (c == "*".code && q.peek() == "/".code) {
								flush(q.pos);
								out += "\\";
								start = q.pos;
								break;
							}
						}
					};
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				case "#".code if ((p == 0 || q.get(p - 1) == "\n".code) && q.substr(p, 5) == "#gmcr"): {
					found = true;
				};
				default: { };
			}
		}
		if (!found) return code;
		flush(q.pos);
		var proc:String->GmlExtCoroutinesProc = untyped window.gmcr_proc;
		if (proc == null) {
			errorText = "GMCR is not available. Did you copy it from pre-built binary or it's itch.io download?";
			return null;
		}
		var pair = proc(out);
		if (pair.code == null) {
			errorText = "Coroutine compilation failed:\n" + pair.error;
			return null;
		}
		return pair.code + "\r\n" + prefix + "\r\n" + out + "\r\n" + suffix + "\r\n";
	}
}
private typedef GmlExtCoroutinesProc = { code:String, error:String };
