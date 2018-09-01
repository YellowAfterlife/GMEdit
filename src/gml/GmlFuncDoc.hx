package gml;
import js.RegExp;
import parsers.GmlReader;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFuncDoc {
	
	public var name:String;
	
	/** "func(" */
	public var pre:String;
	
	/** "): doc" */
	public var post:String;
	
	/** array of argument names */
	public var args:Array<String>;
	
	/** whether to show "..." in the end of argument list */
	public var rest:Bool;
	
	/** Whether this is an incomplete/accumulating doc */
	public var acc:Bool = false;
	
	public function new(name:String, pre:String, post:String, args:Array<String>, rest:Bool) {
		this.name = name;
		this.pre = pre;
		this.post = post;
		this.args = args;
		this.rest = rest;
	}
	
	public function getAcText() {
		return pre + args.join(", ") + post;
	}
	
	public static function parse(s:String, ?out:GmlFuncDoc) {
		var p0 = s.indexOf("(");
		var p1 = s.indexOf(")", p0);
		var name:String, pre:String, post:String, args:Array<String>, rest:Bool;
		if (p0 >= 0 && p1 >= 0) {
			name = s.substring(0, p0);
			var sw = s.substring(p0 + 1, p1).trimBoth();
			pre = s.substring(0, p0 + 1);
			post = s.substring(p1);
			if (sw != "") {
				args = sw.splitReg(js.Syntax.code("/,\\s*/g"));
			} else args = [];
			rest = sw.indexOf("...") >= 0;
		} else {
			name = s;
			pre = s;
			post = "";
			args = [];
			rest = false;
		}
		if (out != null) {
			out.name = name;
			out.pre = pre;
			out.post = post;
			out.args = args;
			out.rest = rest;
			return out;
		} else return new GmlFuncDoc(name, pre, post, args, rest);
	}
	
	static var autogen_argi = [for (i in 0 ... 16) new RegExp('\\bargument$i\\b')];
	static var autogen_argoi = [for (i in 0 ... 16) new RegExp('\\bargument\\s*\\[\\s*$i\\s*\\]')];
	static var autogen_argo = new RegExp("\\bargument\\b");
	
	public static function autoArgs(code:String) {
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
