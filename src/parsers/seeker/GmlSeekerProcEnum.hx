package parsers.seeker;
import ace.extern.AceAutoCompleteItem;
import gml.GmlEnum;
import js.lib.RegExp;
import parsers.seeker.GmlSeekerImpl;
import parsers.seeker.GmlSeekerParser;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerProcEnum {
	private static var parseConst_rx10 = new RegExp("^-?\\d+$");
	private static var parseConst_rx16 = new RegExp("^(?:0x|\\$)([0-9a-fA-F]+)$");
	public static function parseConst(s:String):Null<Int> {
		var mt = parseConst_rx10.exec(s);
		if (mt != null) return Std.parseInt(s);
		mt = parseConst_rx16.exec(s);
		if (mt != null) return Std.parseInt("0x" + mt[1]);
		return null;
	}
	
	public static function proc(seeker:GmlSeekerImpl) {
		var name = seeker.find(Ident);
		if (name == null) return;
		if (seeker.find(Cub0) == null) return;
		var out = seeker.out;
		var q = seeker.reader;
		var orig = seeker.orig;
		var sub = seeker.sub;
		
		var en = new GmlEnum(name, orig);
		out.enums[name] = en;
		out.comps[name] = new AceAutoCompleteItem(name, "enum");
		seeker.setLookup(name);
		var nextVal:Null<Int> = 0;
		while (q.loop) {
			var s = seeker.find(Ident | Cub1);
			if (s == null || s == "}") break;
			en.lastItem = s;
			en.names.push(s);
			en.items.set(s, true);
			var ac = new AceAutoCompleteItem(name + "." + s, "enum");
			var acf = new AceAutoCompleteItem(s, "enum");
			en.compList.push(ac);
			en.fieldComp.push(acf);
			en.compMap.set(s, ac);
			en.fieldLookup.set(s, { path: orig, sub: sub, row: seeker.row, col: 0, });
			s = seeker.find(Comma | SetOp | Cub1);
			if (s == "=") {
				//
				var doc = null;
				var vp = q.pos;
				while (vp < q.length) {
					var c = q.get(vp++);
					switch (c) {
						case "\r".code, "\n".code: break;
						case "/".code if (q.get(vp) == "/".code): {
							var docStart = ++vp;
							while (vp < q.length) {
								c = q.get(vp);
								if (c == "\r".code || c == "\n".code) break;
								vp++;
							}
							doc = q.substring(docStart, vp).trimBoth();
						};
					}
				}
				//
				vp = q.pos;
				s = seeker.find(Comma | Cub1);
				var val = parseConst(q.substring(vp, q.pos - 1).trimBoth());
				if (val != null) {
					acf.doc = ac.doc = "" + val;
					nextVal = val + 1;
				} else nextVal = null;
				if (doc != null) {
					acf.doc = acf.doc != null ? acf.doc + "\t" + doc : doc;
					ac.doc = acf.doc;
				}
			} else if (nextVal != null) {
				acf.doc = ac.doc = "" + (nextVal++);
			}
			if (s == null || s == "}") break;
		}
	}
}