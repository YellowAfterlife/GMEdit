package synext;
import js.lib.RegExp;
import js.lib.RegExp.RegExpMatch;
import parsers.GmlReader;
import tools.Aliases;
import tools.GmlCodeTools;
import tools.JsTools;
using tools.RegExpTools;

/**
 * Borrowing the idea from JS/TS/C#
 * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Logical_nullish_assignment
 * https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/proposals/csharp-8.0/null-coalescing-assignment
 * 
 * Very good for 2.3 optional arguments and... not much else, really.
 * 
 * @author YellowAfterlife
 */
class GmlNullCoalescingAssignment {
	static var rxPre = new RegExp("if"
		+ "(\\s*)" // 1
		+ "\\("
		+ "([^()]+?)" // 2 - condition
		+ "(\\s*)" // 3
		+ "=="
		+ "(\\s*)" // 4
		+ "undefined"
		+ "\\)"
		+ "(\\s*)" // 5
		+ "([^()]+?)" // 6
		+ "(\\s*)" // 7
		+ "="
	, "g");
	public static function pre(code:GmlCode):GmlCode {
		var q = new GmlReader(code);
		var version = gml.GmlAPI.version;
		var out = "";
		var start:StringPos = 0;
		var rx = rxPre;
		var stringsFrom:Array<StringPos> = [];
		var stringsTill:Array<StringPos> = [];
		function flush(till:StringPos):Void {
			rx.each(code, function(mt:RegExpMatch) {
				// validate consistency:
				var sp = mt[1];
				var ex = mt[2];
				if (mt[3] != sp
					|| mt[4] != sp
					|| mt[5] != sp
					|| mt[7] != sp
					|| mt[6] != ex
					|| GmlCodeTools.skipDotExprBackwards(ex, ex.length) != 0
				) return;
				// make sure it's not in a string
				var ind = mt.index;
				var i = stringsFrom.length;
				while (--i >= 0) {
					if (ind >= stringsFrom[i] && ind < stringsTill[i]) break;
				}
				if (i >= 0) return;
				//
				out += code.substring(start, ind)
					+ '$ex$sp??=';
				start = ind + mt[0].length;
			}, start, till);
			out += code.substring(start, till);
			stringsFrom.resize(0);
			stringsTill.resize(0);
		}
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: {
						flush(p);
						q.skipLine();
						out += code.substring(p, q.pos);
						start = q.pos;
					}
					case "*".code: {
						flush(p);
						q.skip();
						q.skipComment();
						out += code.substring(p, q.pos);
						start = q.pos;
					}
					default:
				};
				case '"'.code, "'".code, "@".code: {
					q.skipStringAuto(c, version);
					if (q.pos > p + 1) {
						stringsFrom.push(p);
						stringsTill.push(q.pos);
					}
				};
				case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
					q.readContextName(null);
				};
				default:
			}
		}
		flush(q.length);
		return out;
	}
	public static function post(code:GmlCode):GmlCode {
		var q = new GmlReader(code);
		var version = gml.GmlAPI.version;
		var out = "";
		var start:StringPos = 0;
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
				case '"'.code, "'".code, "@".code: q.skipStringAuto(c, version);
				case "?".code if (q.peek() == "?".code && q.peek(1) == "=".code): {
					var exEnd = p;
					while (exEnd >= 0) {
						c = q.get(exEnd - 1);
						if (c.isSpace0()) exEnd--; else break;
					}
					var exStart = GmlCodeTools.skipDotExprBackwards(code, exEnd);
					var ex = code.substring(exStart, exEnd);
					var sp = code.substring(exEnd, p);
					out += code.substring(start, exStart)
						+ 'if$sp($ex$sp==${sp}undefined)${sp}$ex$sp=';
					start = q.pos + 2;
				};
				default:
			}
		}
		flush(q.pos);
		return out;
	}
}