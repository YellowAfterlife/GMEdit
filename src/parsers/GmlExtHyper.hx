package parsers;
import ui.Preferences;
import gml.GmlAPI;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtHyper {
	public static function pre(code:String):String {
		if (!Preferences.current.argsMagic) return code;
		var version = GmlAPI.version;
		var q = new GmlReader(code);
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: {
						q.skipLine();
						if (q.get(p + 2) == "!".code
						&& q.get(p + 3) == "#".code
						&& q.substr(p + 4, 5) == "hyper") {
							flush(p);
							out += q.substring(p + 3, q.pos);
							start = q.pos;
						}
					};
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
					var ctx = q.readContextName(null);
				};
				default:
			}
		}
		flush(q.pos);
		return out;
	}
	public static function post(code:String):String {
		if (!Preferences.current.argsMagic) return code;
		var version = GmlAPI.version;
		var q = new GmlReader(code);
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				case "#".code: {
					if (q.substr(p + 1, 5) == "hyper") {
						q.skipLine();
						flush(p);
						out += "//!" + q.substring(p, q.pos);
						start = q.pos;
					} else if (p == 0 || q.get(p - 1) == "\n".code) {
						var ctx = q.readContextName(null);
					}
				};
				default:
			}
		}
		flush(q.pos);
		return out;
	}
}
