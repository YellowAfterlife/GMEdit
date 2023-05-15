package synext;
import editors.EditCode;
import file.kind.KGml;
import synext.SyntaxExtension;
import ui.Preferences;
import gml.GmlAPI;
import parsers.GmlReader;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtHyper extends SyntaxExtension {
	public static var inst:GmlExtHyper = new GmlExtHyper();
	
	function new() {
		super("#hyper", "#hyper magic");
	}
	
	override public function check(editor:EditCode, code:String):Bool {
		return (cast editor.kind:KGml).canHyper;
	}
	
	override public function preproc(editor:EditCode, code:String):String {
		code = pre(code);
		if (code == null) message = errorText;
		return code;
	}
	
	override public function postproc(editor:EditCode, code:String):String {
		code = post(code);
		if (code == null) message = errorText;
		return code;
	}
	
	public static var errorText:String;
	
	public static function pre(code:String):String {
		if (!Preferences.current.hyperMagic) return code;
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
				case "$".code if (q.isDqTplStart(version)): q.skipDqTplString(version);
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
		if (!Preferences.current.hyperMagic) return code;
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
				case "$".code if (q.isDqTplStart(version)): q.skipDqTplString(version);
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
