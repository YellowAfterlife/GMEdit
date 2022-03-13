package synext;
import editors.EditCode;
import parsers.GmlReader;
import tools.JsTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtHashColorLiterals extends SyntaxExtension {
	public static var inst:GmlExtHashColorLiterals = new GmlExtHashColorLiterals();
	public function new() {
		super("#color", "#color literals");
	}
	override public function preproc(editor:EditCode, code:String):String {
		var q = new GmlReader(code);
		var out = "";
		var rx = JsTools.rx(~/#\*\/(?:0x|\$)([0-9a-fA-F]{6,6})\b/);
		var start = 0;
		inline function flush(till:Int):Void {
			out += q.substring(start, till);
		}
		while (q.loopLocal) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: {
						q.skip();
						// "#*/0x123456"
						var mt = rx.exec(q.peekstr(12));
						if (mt != null) {
							flush(p);
							var c = mt[1];
							out += "#" + c.substr(4, 2) + c.substr(2, 2) + c.substr(0, 2);
							q.skip(mt[0].length);
							start = q.pos;
						} else {
							q.skipComment();
						}
					};
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, q.version);
				case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
					q.readContextName(null);
				};
				default:
			}
		}
		flush(q.pos);
		return out;
	}
	override public function postproc(editor:EditCode, code:String):String {
		if (gml.Project.current.version.hasColorLiterals()) return code;
		var q = new GmlReader(code);
		var v = q.version;
		var v2 = v.hasLiteralStrings();
		var out = "";
		var rx = JsTools.rx(~/([0-9a-fA-F]{6,6})\b/);
		var start = 0;
		inline function flush(till:Int):Void {
			out += q.substring(start, till);
		}
		while (q.loopLocal) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, v);
				case "#".code: {
					if ((p == 0 || q.get(p - 1) != "[".code) && rx.test(q.peekstr(7))) {
						flush(p);
						out += ("/*#*/"
							+ (v2 ? "0x" : "$")
							+ q.peekstr(2, 4)
							+ q.peekstr(2, 2)
							+ q.peekstr(2, 0)
						);
						q.pos += 6;
						start = q.pos;
					} else if (p == 0 || q.get(p - 1) == "\n".code) {
						q.readContextName(null);
					};
				};
				default:
			}
		}
		flush(q.pos);
		return out;
	}
}