package gml.type;
import gml.type.GmlType;
import parsers.GmlReader;
import tools.Dictionary;
import tools.JsTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlTypeParser {
	static var kindMeta:Dictionary<GmlTypeKind> = (function() {
		var r = new Dictionary();
		r["any"] = KAny;
		r["Any"] = KAny;
		r["Null"] = KNullable;
		r["type"] = KType;
		r["Type"] = KType;
		r["void"] = KVoid;
		r["Void"] = KVoid;
		r[GmlTypeTools.templateItemName] = KTemplateItem;
		r[GmlTypeTools.templateSelfName] = KTemplateSelf;
		r["global"] = KGlobal;
		r["function"] = KFunction;
		r["rest"] = KRest;
		//
		r["undefined"] = KUndefined;
		r["int"] = KNumber;
		r["Int"] = KNumber;
		r["number"] = KNumber;
		r["Number"] = KNumber;
		r["string"] = KString;
		r["String"] = KString;
		r["bool"] = KBool;
		r["Bool"] = KBool;
		//
		r["array"] = KArray;
		r["Array"] = KArray;
		r["ds_list"] = KList;
		r["ds_grid"] = KGrid;
		r["ds_map"] = KMap;
		//
		r["object"] = KObject;
		r["instance"] = KObject;
		r["struct"] = KStruct;
		r["asset"] = KAsset;
		//
		return r;
	})();
	public static var warnAboutMissing:Array<String> = null;
	static function parseError(s:String, q:GmlReader, ?pos:Int):GmlType {
		if (pos == null) pos = q.pos - 1;
		Console.warn("Type parse error in `" + q.source.insert(pos, '¦') + "`: " + s);
		return null;
	}
	public static function parseRec(q:GmlReader, flags:GmlTypeParserFlags = FNone):GmlType {
		// also see GmlReader.skipType, GmlLinter.readTypeName
		q.skipSpaces0_local();
		var start = q.pos;
		var c = q.read();
		var result:GmlType;
		switch (c) {
			case "(".code:
				result = parseRec(q);
				if (result == null) return null;
				q.skipSpaces0_local();
				if (q.read() != ")".code) return parseError("Unclosed ()", q, start);
			case _ if (c.isIdent0()):
				q.skipIdent1();
				q.skipSpaces0_local();
				var name = q.substring(start, q.pos);
				var kind = JsTools.or(kindMeta[name], KCustom);
				var params = [];
				//
				var typeWarn = warnAboutMissing;
				//
				var isTIN = (name == GmlTypeTools.templateItemName);
				if (q.peek() == "<".code) {
					q.skip();
					while (q.loop) {
						// disable warnings for name and _index
						warnAboutMissing = (isTIN && params.length < 2) ? null : typeWarn;
						var t = parseRec(q);
						if (t == null) return null;
						params.push(t);
						q.skipSpaces0_local();
						c = q.read();
						switch (c) {
							case ">".code: break;
							case ",".code, ";".code: // OK!
							default: return parseError("Expected a `,`/`;` or a `>` in `<>`", q);
						}
					}
					if (isTIN) warnAboutMissing = typeWarn;
				}
				if (kind == KTemplateItem) {
					if (params.length < 2) return parseError("Malformed parameters for " + GmlTypeTools.templateItemName, q);
					var tn = switch (params[0]) {
						case null: "?";
						case TInst(s, [], KCustom): s;
						default: "?";
					}
					var ti = switch (params[1]) {
						case null: null;
						case TInst(s, [], KCustom) if (s.fastCodeAt(0) == "_".code): Std.parseInt(s.substr(1));
						default: null;
					}
					if (ti == null) return parseError("Malformed index for " + GmlTypeTools.templateItemName, q);
					result = TTemplate(tn, ti, params[2]);
				} else {
					if (typeWarn != null
						&& !GmlAPI.stdKind.exists(name)
						&& !GmlTypeTools.kindMap.exists(name)
						&& name != "undefined"
					) typeWarn.push(name);
					result = TInst(name, params, kind);
				}
			default:
				return parseError("Expected a type name", q);
		}
		
		// postfixes:
		while (q.loop) {
			q.skipSpaces0_local();
			switch (q.peek()) {
				case "[".code:
					q.skip();
					if (q.read() != "]".code) return parseError("Expected a `]` in `[]`", q);
					result = TInst("Array", [result], KArray);
				case "?".code:
					q.skip();
					if (!result.isNullable()) result = TInst("Nullable", [result], KNullable);
				case "|".code:
					if ((flags & FNoEither) != 0) break;
					q.skip();
					var et = [result];
					while (q.loop) {
						var t = parseRec(q, FNoEither);
						if (t == null) return null;
						et.push(t);
						q.skipSpaces0_local();
						if (q.peek() == "|".code) q.skip(); else break;
					}
					result = TEither(et);
				default: break;
			}
		}
		return result;
	}
	
	static var cache:Dictionary<GmlType> = new Dictionary();
	public static function parse(s:String):GmlType {
		if (s == null) return null;
		var t = cache[s];
		if (t != null) return t;
		var q = new GmlReader(s);
		t = parseRec(q);
		q.skipSpaces0();
		if (q.loopLocal) Console.warn("Type parse warning in `"
			+ s.insert(q.pos, "¦") + "`: Trailing data");
		cache[s] = t;
		return t;
	}
	public static function clear():Void {
		cache = new Dictionary();
	}
}
enum abstract GmlTypeParserFlags(Int) from Int to Int {
	var FNone = 0;
	var FNoEither = 1;
}