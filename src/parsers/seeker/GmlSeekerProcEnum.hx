package parsers.seeker;
import ace.extern.AceAutoCompleteItem;
import gml.GmlEnum;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import js.lib.RegExp;
import parsers.seeker.GmlSeekerImpl;
import parsers.seeker.GmlSeekerJSDocRegex;
import parsers.seeker.GmlSeekerParser;
import tools.JsTools;
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
	
	static var maxTupleTypes:Int = 256;
	static var jsDoc_enumField_is_line = (function() {
		var id = "[_a-zA-Z]\\w*";
		return new RegExp("^\\s*"
			+ '($id(?:\\s*,\\s*$id)*)'
		);
	})();
	
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
		
		function checkDoc(s:String):Bool {
			if (s == null || !s.startsWith("///")) return false;
			var isMatch = GmlSeekerJSDocRegex.jsDoc_is.exec(s);
			if (isMatch == null) return true;
			var typeStr = isMatch[1];
			var type = GmlTypeDef.parse(typeStr, "@is in enum at line " + q.row);
			var info = isMatch[2];
			
			var lineStart = q.source.lastIndexOf("\n", q.pos - 1) + 1;
			var lineText = q.source.substring(lineStart, q.pos);
			var lineMatch = jsDoc_enumField_is_line.exec(lineText);
			if (lineMatch == null) return true;
			
			tools.RegExpTools.each(JsTools.rx(~/\w+/g), lineMatch[1], function(mt) {
				var name = mt[0];
				
				var ac = en.compMap[name];
				if (ac == null) return;
				
				var ind = Std.parseInt(ac.doc);
				if (ind == null) return;
				
				if (en.tupleTypes == null) en.tupleTypes = [];
				if (ind < maxTupleTypes) {
					en.tupleTypes[ind] = type;
				} else if (en.tupleTypes.length < maxTupleTypes) {
					en.tupleTypes[maxTupleTypes - 1] = GmlTypeDef.rest([GmlTypeDef.any]);
				}
			});
			
			return true;
		}
		function next(flags:Int) {
			flags |= Doc;
			while (q.loop) {
				var s = seeker.find(flags);
				if (checkDoc(s)) continue;
				return s;
			}
			return null;
		}
		
		var nextVal:Null<Int> = 0;
		while (q.loop) {
			var s = next(Ident | Cub1);
			if (s == null || s == "}") break;
			
			var itemRow = seeker.reader.row;
			en.lastItem = s;
			en.names.push(s);
			en.items.set(s, true);
			var ac = new AceAutoCompleteItem(name + "." + s, "enum");
			var acf = new AceAutoCompleteItem(s, "enum");
			en.compList.push(ac);
			en.fieldComp.push(acf);
			en.compMap.set(s, ac);
			en.fieldLookup.set(s, { path: orig, sub: sub, row: q.row, col: 0, });
			
			s = next(Comma | SetOp | Cub1);
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
				s = next(Comma | Cub1);
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
		
		if (en.tupleTypes != null) do {
			var ac = en.compMap[en.lastItem];
			if (ac == null) break;
			
			var ind = Std.parseInt(ac.doc);
			if (ind == null) break;
			ind -= 1;
			if (ind < maxTupleTypes && en.tupleTypes.length < ind) {
				en.tupleTypes[ind] = null;
			}
			
		} while (false);
	}
}