package gml.funcdoc;
import js.lib.RegExp;
import parsers.GmlReader;

/**
 * Very cheaply generates an arguments-string based on `argument#`/`argument[#]` uses in code.
 * Only used for generating placeholders for <=2.2 #lambda
 * @author YellowAfterlife
 */
class GmlFuncDocCheapArgs {
	static var autogen_argi = [for (i in 0 ... 16) new RegExp('\\bargument$i\\b')];
	static var autogen_argoi = [for (i in 0 ... 16) new RegExp('\\bargument\\s*\\[\\s*$i\\s*\\]')];
	static var autogen_argo = new RegExp("\\bargument\\b");
	
	public static function parse(code:String):String {
		var q = new GmlReader(code);
		var rxi = autogen_argi;
		var rxo = autogen_argo;
		var rxoi = autogen_argoi;
		var rxc = rxi;
		var trail = false;
		var argc = 0;
		var chunk:String;
		var start = 0;
		inline function flush(p:Int) {
			chunk = q.substring(start, p);
			if (!trail && rxo.test(chunk)) {
				trail = true;
				rxc = rxoi;
			}
			while (argc < 16) {
				if (rxc[argc].test(chunk)) argc += 1; else break;
			}
		}
		while (q.loop) {
			var p = q.pos;
			var n = q.skipCommon_inline();
			if (n >= 0) {
				flush(p);
				start = q.pos;
			} else q.skip();
		}
		flush(q.pos);
		if (argc == 0) return trail ? "..." : "";
		var out = "v0";
		for (i in 1 ... argc) out += ", v" + i;
		if (trail) out += ", ...";
		return out;
	}
}