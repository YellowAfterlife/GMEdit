package synext;
import editors.EditCode;
import parsers.GmlReader;
import synext.SyntaxExtension;
import tools.CharCode;
import ui.Preferences;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtCast extends SyntaxExtension {
	public static var inst:GmlExtCast = new GmlExtCast();
	public function new() {
		super("cast/as", "cast/as operators");
	}
	override public function check(editor:EditCode, code:String):Bool {
		return Preferences.current.castOperators;
	}
	override public function preproc(editor:EditCode, code:String):String {
		var q = new GmlReader(code);
		var v = q.version;
		var start = 0;
		var out = "";
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		while (q.loopLocal) {
			var p = q.pos;
			var c:CharCode = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: {
						q.skip();
						var isHash = q.peek() == "#".code;
						q.skipComment();
						if (!isHash) continue;
						// make sure we don't produce a `identcast`:
						if (p > 0) {
							c = q.get(p - 1); if (c.isIdent1()) continue;
						}
						// make sure we don't produce a `castident`:
						c = q.peek(); if (c.isIdent1()) continue;
						
						var len = q.pos - 5 - p;
						if (len == 4 && q.substr(p + 3, 4) == "cast") {
							flush(p);
							out += "cast";
							start = q.pos;
						} else if (len >= 3 && q.substr(p + 3, 2) == "as" && !q.get(p + 5).isIdent1_ni()) {
							var cmtEnd = q.pos;
							q.pos = p + 5;
							if (!q.skipType() || q.pos != cmtEnd - 2) {
								q.pos = cmtEnd;
							} else {
								flush(p);
								out += q.substring(p + 3, q.pos);
								start = cmtEnd;
							}
						}
					};
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, v);
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
		var q = new GmlReader(code);
		var v = q.version;
		var start = 0;
		var out = "";
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		while (q.loopLocal) {
			var p = q.pos;
			var c:CharCode = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, v);
				case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
					q.readContextName(null);
				};
				case _ if (c.isIdent0()): {
					var p = q.pos - 1;
					q.skipIdent1();
					var id = q.substring(p, q.pos);
					if (id == "cast"
						|| id == "as" && q.skipType()
					) {
						flush(p);
						out += "/*#" + q.substring(p, q.pos) + "*/";
						start = q.pos;
					}
				};
				default:
			}
		}
		flush(q.pos);
		return out;
	}
}