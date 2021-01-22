package synext;
import editors.EditCode;
import file.kind.KGml;
import gml.GmlAPI;
import gml.Project;
import js.lib.RegExp;
import js.lib.RegExp.RegExpMatch;
import parsers.GmlReader;
import synext.SyntaxExtension;
import tools.Aliases;
import tools.GmlCodeTools;
import tools.JsTools;
import ui.Preferences;
using tools.RegExpTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlNullCoalescingOperator extends SyntaxExtension {
	public static var inst:GmlNullCoalescingOperator = new GmlNullCoalescingOperator();
	
	public function new() {
		super("??", "null-coalescing operators");
	}
	
	override public function check(editor:EditCode, code:String):Bool {
		return Std.is(editor.kind, KGml) && (cast editor.kind:KGml).canNullCoalescingOperator;
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
	
	public static function pre(code:GmlCode):GmlCode {
		var q = new GmlReader(code);
		var version = GmlAPI.version;
		var out = "";
		var start = 0;
		var ncSet = Project.current.properties.nullConditionalSet;
		var ncVal = Project.current.properties.nullConditionalVal;
		if (ncSet == null || ncVal == null) return code;
		inline function flush(till:StringPos):Void {
			out += code.substring(start, till);
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
				case '"'.code, "'".code, "@".code: q.skipStringAuto(c, version);
				case "#".code: if (q.canContextName(p)) q.readContextName(null);
				case _ if (c.isIdent0()): {
					q.skipIdent1();
					var id = q.substring(p, q.pos);
					if (id != ncSet) continue;
					if (q.read() != "(".code) continue;
					var exprStart = q.pos;
					if (!q.skipBalancedParenExpr()) continue;
					var expr = q.substring(exprStart, q.pos - 1);
					//
					var spaceStr:String = {
						var spStart = q.pos;
						q.skipSpaces0();
						q.substring(spStart, q.pos);
					};
					var skipValSpace_start:StringPos;
					inline function skipValSpace():Bool {
						skipValSpace_start = q.pos;
						q.skipSpaces0();
						return q.substring(skipValSpace_start, q.pos) != spaceStr;
					}
					// nc_set(a) ¦? nc_val.b : c
					if (q.read() != "?".code) continue;
					if (skipValSpace()) continue;
					if (q.readIdent() != ncVal) continue;
					
					var c1 = q.peek();
					if (c1 == ".".code || c1 == "[".code) { // nc_set(a) ? nc_val¦.b : c
						q.skip(); // nc_val.¦b
						
						var fdStart = q.pos;
						var fdSuffix:String;
						if (c1 == "[".code) {
							if (!q.skipBalancedParenExpr()) continue;
						} else {
							q.skipSpaces0(); // optional spacing before field name
							if (q.readIdent() == null) continue;
						}
						fdSuffix = q.substring(fdStart, q.pos); // nc_val.b¦
						
						if (skipValSpace()) continue;
						if (q.read() != ":".code) continue;
						if (skipValSpace()) continue;
						if (q.readIdent() != "undefined") continue;
						if (q.read() != ")".code) continue;
						
						//
						if (q.get(p - 1) != "(".code) continue;
						flush(p - 1);
						var op = c1 == "[".code ? "?[" : "?.";
						out += pre(expr) + spaceStr + op + fdSuffix;
					} else {
						if (skipValSpace()) continue;
						if (q.read() != ":".code) continue;
						//
						flush(p);
						out += pre(expr) + spaceStr + "??";
					}
					start = q.pos;
					//Main.console.log(id);
				};
				default:
			}
		}
		flush(q.length);
		return out;
	}
	
	public static function post(code:GmlCode):GmlCode {
		var ncSet = Project.current.properties.nullConditionalSet;
		var ncVal = Project.current.properties.nullConditionalVal;
		if (ncSet == null || ncVal == null) return code;
		var q = new GmlReader(code);
		var version = GmlAPI.version;
		var segments = [];
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "@".code: q.skipStringAuto(c, version);
				case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
					q.readContextName(null);
				};
				case "?".code: {
					var c1 = q.peek();
					if (c1 == "?".code || c1 == ".".code || c1 == "[".code) {
						q.skip();
						//
						var fdSuffix:String;
						switch (c1) {
							case ".".code: {
								var fdStart = q.pos;
								q.skipSpaces0();
								if (!q.peek().isIdent0()) continue; // don't convert `z?.1:.2`
								q.skipIdent1();
								fdSuffix = q.substring(fdStart, q.pos);
							};
							case "[".code: {
								var parStart = q.pos;
								if (!q.skipBalancedParenExpr()) continue;
								var np = q.pos, isTernary = false;
								while (np < q.length) {
									var nc = q.get(np++);
									if (nc.isSpace1()) continue;
									isTernary = nc == ":".code;
									break;
								}
								if (isTernary) continue;
								fdSuffix = q.substring(parStart, q.pos);
							};
							default: fdSuffix = null;
						}
						//
						var exprEnd = p;
						while (exprEnd > 0) {
							c = q.get(exprEnd - 1);
							if (c.isSpace0()) exprEnd--; else break;
						}
						var exprStart = GmlCodeTools.skipDotExprBackwards(code, exprEnd);
						var expr = code.substring(exprStart, exprEnd);
						//
						var sp = code.substring(exprEnd, p);
						segments.push({
							full: code.substring(exprStart, q.pos),
							start: exprStart,
							end: q.pos,
							expr: expr,
							space: sp,
							fdSuffix: fdSuffix,
							kind: c1,
							recurse: false,
						});
					};
				};
				default:
			}
		}
		//
		var out = "";
		var start = 0;
		inline function flush(till:StringPos):Void {
			out += code.substring(start, till);
		}
		// merge segments containing other segments:
		var i = segments.length;
		while (--i >= 0) {
			var seg = segments[i];
			while (i > 0) {
				var s1 = segments[i - 1];
				if (s1.start >= seg.start && s1.end <= seg.end) {
					seg.recurse = true;
					segments.splice(i - 1, 1);
					i -= 1;
				} else break;
			}
		}
		//
		for (seg in segments) {
			flush(seg.start);
			var sp = seg.space;
			var expr = seg.expr;
			if (seg.recurse) expr = post(expr);
			switch (seg.kind) {
				case ".".code: {
					out += '($ncSet($expr)'
						+ sp + "?"
						+ sp + ncVal + "." + seg.fdSuffix
						+ sp + ":"
						+ sp + "undefined"
					+ ')';
				};
				case "[".code: {
					out += '(nc_set($expr)'
						+ sp + "?"
						+ sp + ncVal + "[" + seg.fdSuffix
						+ sp + ":"
						+ sp + "undefined"
					+ ')';
				};
				default: out += '$ncSet($expr)${sp}?${sp}$ncVal${sp}:';
			}
			start = seg.end;
		}
		flush(q.length);
		//
		return out;
	}
}