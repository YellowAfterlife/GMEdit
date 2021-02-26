package gml.funcdoc;
import gml.GmlFuncDoc;
import tools.Aliases;
import parsers.GmlReader;
import js.lib.RegExp;
using tools.NativeString;

/**
 * Figures out whether arguments are optional and whether the script returns anything.
 * @author YellowAfterlife
 */
class GmlFuncDocArgsRet {
	public static var rxHasArgArray:RegExp = new RegExp("\\bargument\\b\\s*\\[");
	public static function proc(doc:GmlFuncDoc, gml:GmlCode, from:Int = 0, ?_till:Int, ?isAuto:Bool, ?autoArgs:Array<String>) {
		var start = from;
		var till:Int = _till != null ? _till : gml.length;
		var q = new GmlReader(gml);
		var chunk:GmlCode;
		var hasRetRx = @:privateAccess GmlFuncDocFromCode.rxHasReturn;
		var seekHasRet = !doc.hasReturn;
		var seekArg = isAuto && doc.args.length > 0 && !doc.rest;
		var hasArgRx = rxHasArgArray;
		//
		var autoRxs:Array<RegExp> = null;
		if (autoArgs != null) try {
			autoRxs = [];
			for (arg in autoArgs) autoRxs.push(new RegExp('\\b(?:'
				+ arg + '\\s*[!=]=\\s*undefined'
				+ "|is_undefined\\s*\\(\\s*" + arg + "\\s*\\)"
			+ ')'));
		} catch (_:Dynamic) autoRxs = null;
		inline function checkAutoRxs() {
			if (autoRxs == null) return;
			var m = @:privateAccess doc.minArgsCache;
			if (m == 0) return;
			var n = m != null ? m : autoRxs.length;
			var i = -1; while (++i < n) {
				if (autoRxs[i].test(chunk)) {
					@:privateAccess doc.minArgsCache = i;
					break;
				}
			}
		}
		//
		function flush(p:Int) {
			chunk = q.substring(start, p);
			if (seekHasRet && hasRetRx.test(chunk)) {
				seekHasRet = false;
				doc.returnTypeString = "";
				if (!seekArg) return;
			}
			if (seekArg && hasArgRx.test(chunk)) {
				// mimicking 2.3 IDE behaviour where having
				// argument[] access makes all arguments optional.
				seekArg = false;
				@:privateAccess doc.minArgsCache = 0;
				doc.rest = true;
				if (!seekHasRet) return;
			}
			checkAutoRxs();
			start = q.pos;
		}
		q.pos = from;
		while (q.pos < till) {
			var p = q.pos;
			var n = q.skipCommon_inline();
			if (n >= 0) {
				flush(p);
			} else if (q.peek().isIdent0_ni() && q.readIdent() == "function") {
				flush(p);
				var depth = 0;
				while (q.pos < till) {
					switch (q.peek()) {
						case "{".code: q.skip(); depth++;
						case "}".code: q.skip(); if (--depth <= 0) break;
						default:
							if (q.skipCommon_inline() >= 0) {
								//
							} else q.skip();
					}
				}
				start = q.pos;
			} else q.skip();
		}
		chunk = q.substring(start, q.pos);
		// final:
		if (seekHasRet) {
			var hasRet = hasRetRx.test(chunk);
			if (hasRet) {
				if (doc.returnTypeString == null) doc.returnTypeString = "";
			} else doc.returnTypeString = null;
			doc.hasReturn = hasRet;
		}
		if (seekArg && hasArgRx.test(chunk)) {
			@:privateAccess doc.minArgsCache = 0;
			doc.rest = true;
		}
		checkAutoRxs();
	}
}