package parsers.seeker;
import gml.GmlAPI;
import gml.GmlMacro;
import parsers.seeker.GmlSeekerImpl;
import tools.CharCode;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerProcMacro {
	public static function proc(seeker:GmlSeekerImpl) {
		var q = seeker.reader;
		q.skipSpaces0();
		var c = q.peek(); if (!c.isIdent0()) return;
		var p = q.pos;
		q.skipIdent1();
		var name = q.substring(p, q.pos);
		// `#macro Config:name`?
		var cfg:String;
		if (q.peek() == ":".code) {
			q.skip();
			c = q.peek();
			if (c.isIdent0()) {
				p = q.pos;
				q.skipIdent1();
				cfg = name;
				name = q.substring(p, q.pos);
			} else cfg = null;
		} else cfg = null;
		q.skipSpaces0();
		// value:
		p = q.pos;
		var expr = "";
		do {
			q.skipLine();
			if (q.peek( -1) == "\\".code) {
				expr += q.substring(p, q.pos - 1) + "\n";
				q.skipLineEnd();
				p = q.pos;
				q.row += 1;
			} else break;
		} while (q.loopLocal);
		expr += q.substring(p, q.pos);
		// we don't currently support configuration nesting
		if (cfg == null || cfg == seeker.project.config) {
			var m = new GmlMacro(name, seeker.orig, expr, cfg);
			var out = seeker.out;
			if (out.macros.exists(name)) {
				out.comps.remove(name);
			} else {
				out.kindList.push(name);
				if (GmlAPI.stdKind[m.expr] == "keyword") {
					// keyword forwarding
					out.kindMap[name] = "keyword";
				} else {
					out.kindMap[name] = "macro";
				}
			}
			//
			var i = name.indexOf("_mf");
			if (i < 0 || !out.mfuncs.exists(name.substring(0, i))) {
				out.comps[name] = m.comp;
				seeker.setLookup(name, true);
			} else {
				// adjust for mfunc rows being hidden
				q.row -= 1;
			}
			//
			out.macros[name] = m;
		}
	}
}