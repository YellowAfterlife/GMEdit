package gml.type;
import gml.type.GmlType;
import parsers.GmlReader;
import parsers.linter.GmlLinter;
import tools.Aliases;
import tools.Dictionary;
import tools.JsTools;
import ace.AceMacro.jsRx;
import js.html.Console;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlTypeParser {
	static var kindMeta:Dictionary<GmlTypeKind> = (function() {
		var r:Dictionary<GmlTypeKind> = new Dictionary();
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
		r["constructor"] = KConstructor;
		r["rest"] = KRest;
		//
		r["undefined"] = KUndefined;
		r["int"] = KNumber;
		r["Int"] = KNumber;
		r["number"] = KNumber;
		r["Number"] = KNumber;
		r["real"] = KNumber;
		r["Real"] = KNumber;
		r["string"] = KString;
		r["String"] = KString;
		r["bool"] = KBool;
		r["Bool"] = KBool;
		r["boolean"] = KBool;
		//
		r["array"] = KArray;
		r["Array"] = KArray;
		//
		r["ds_list"] = KList;
		r["ds_grid"] = KGrid;
		r["ds_map"] = KMap;
		
		//
		r["ckarray"] = KCustomKeyArray;
		r["CustomKeyArray"] = KCustomKeyArray;
		r["tuple"] = KTuple;
		r["ckstruct"] = KCustomKeyStruct;
		r["CustomKeyStruct"] = KCustomKeyStruct;
		//
		r["object"] = KObject;
		r["instance"] = KObject;
		r["struct"] = KStruct;
		r["asset"] = KAsset;
		//
		r["any_fields_of"] = KAnyFieldsOf;
		r["params_of"] = KParamsOf;
		r["params_of_nl"] = KParamsOfNL;
		r["method_auto_func"] = KMethodFunc;
		r["method_auto_self"] = KMethodSelf;
		r["buffer_auto_type"] = KBufferAutoType;
		//
		return r;
	})();
	public static var warnAboutMissing:Array<String> = null;
	static function parseError(s:String, q:GmlReader, ctx:String, ?pos:Int):GmlType {
		if (pos == null) pos = q.pos - 1;
		Console.warn("Type parse error in `" + q.source.insert(pos, '¦') + '` (`$ctx`): ' + s);
		return null;
	}
	
	static function parseRec_skip(q:GmlReader) {
		while (q.loopLocal) {
			switch (q.peek()) {
				case " ".code, "\t".code, "\r".code, "\n".code: {
					q.skip();
					continue;
				};
				case "/".code: {
					switch (q.peek(1)) {
						case "/".code:
							q.skipLine();
							continue;
						case "*".code:
							q.skip(2);
							q.skipComment();
							continue;
					}
				};
			}; break;
		}
	}
	/**
	 * This function is used by type parser itself.
	 * It is the most accurate of three.
	 */
	public static function parseRec(q:GmlReader, ctx:String, flags:GmlTypeParserFlags = FNone):GmlType {
		inline function parseError(err:String, ?pos:Int):GmlType {
			return GmlTypeParser.parseError(err, q, ctx, pos);
		}
		// also see functions below this one
		parseRec_skip(q);
		var start = q.pos;
		var c = q.read();
		var result:GmlType;
		switch (c) {
			case "[".code: { // `[int, string]` (tuples)
				var params = [];
				while (q.loop) {
					var t = parseRec(q, ctx, FCanAlias);
					if (t == null) return null;
					params.push(t);
					parseRec_skip(q);
					c = q.read();
					switch (c) {
						case "]".code: break;
						case ",".code, ";".code: // OK!
						default: return parseError("Expected a `,`/`;` or a `]` in `[]`");
					}
				}
				result = TInst("tuple", params, KTuple);
			};
			case "{".code: { // `{ a:int, b:string }` (anon structs)
				var ani = new GmlTypeAnon();
				while (q.loop) {
					parseRec_skip(q);
					var field = q.readIdent();
					if (field == null) return parseError("Expected field name in {}");
					
					parseRec_skip(q);
					if (q.read() != ":".code) return parseError("Expected a `:` after field in {}");
					
					var t = parseRec(q, ctx, FCanAlias);
					if (t == null) return null;
					ani.fields[field] = new GmlTypeAnonField(t, null);
					
					switch (q.read()) {
						case "}".code: break;
						case ",".code, ";".code: // OK!
						default: return parseError("Expected a `,`/`;` or a `}` in `{}`");
					}
				}
				result = TAnon(ani);
			};
			case "(".code: { // `(type)` for clarity
				result = parseRec(q, ctx, FCanAlias);
				if (result == null) return null;
				parseRec_skip(q);
				if (q.read() != ")".code) return parseError("Unclosed ()", start);
			};
			case _ if (c.isIdent0()): {
				q.skipDotIdent1();
				var name = q.substring(start, q.pos);
				parseRec_skip(q);
				
				if ((flags & FCanAlias) != 0 && q.peek() == ":".code) {
					q.skip();
					return THint(name, parseRec(q, ctx, flags));
				}
				
				if (name.contains(".")) {
					var nameLq = name.toLowerCase();
					var alt = GmlAPI.featherAliases[nameLq];
					if (alt != null) name = alt;
				}
				
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
						var t = parseRec(q, ctx, FCanAlias);
						if (t == null) return null;
						params.push(t);
						parseRec_skip(q);
						c = q.read();
						switch (c) {
							case ">".code: break;
							case ",".code, ";".code: // OK!
							default: return parseError("Expected a `,`/`;` or a `>` in `<>`");
						}
					}
					if (isTIN) warnAboutMissing = typeWarn;
				}
				if (name == "either") { // Either<A,B> -> (A|B)
					result = TEither(params);
				}
				else if (name == "enum_tuple") {
					var ename = params[0].getNamespace();
					if (ename != null) {
						result = TEnumTuple(ename);
					} else result = TInst(name, params, kind);
				}
				else if (name == "specified_map") {
					var fieldList = [];
					var fieldMap = new Dictionary<GmlTypeMapField>();
					var defaultType = null;
					for (param in params) {
						switch (param) {
							case THint(name, type):
								if (fieldMap.exists(name)) {
									return parseError('Redefinition of field $name');
								} else {
									var field = new GmlTypeMapField(name, type);
									fieldList.push(field);
									fieldMap[name] = field;
								}
							default:
								if (defaultType != null) {
									return parseError('Redefinition of default type');
								} else defaultType = param;
						}
					}
					result = TSpecifiedMap(new GmlTypeMap(fieldMap, fieldList, defaultType));
				}
				else if (kind == KTemplateItem) {
					if (params.length < 2) return parseError("Malformed parameters for " + GmlTypeTools.templateItemName);
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
					if (ti == null) return parseError("Malformed index for " + GmlTypeTools.templateItemName);
					result = TTemplate(tn, ti, params[2]);
				}
				else {
					if (typeWarn != null
						&& !GmlAPI.stdKind.exists(name)
						&& !GmlAPI.stdTypeExists.exists(name)
						&& !GmlTypeTools.kindMap.exists(name)
						&& !kindMeta.exists(name)
					) typeWarn.push(name);
					result = TInst(name, params, kind);
				}
			};
			default:
				return parseError("Expected a type name");
		}
		
		// postfixes:
		while (q.loop) {
			parseRec_skip(q);
			switch (q.peek()) {
				case "[".code:
					q.skip();
					if (q.read() != "]".code) return parseError("Expected a `]` in `[]`");
					result = TInst("Array", [result], KArray);
				case "?".code:
					q.skip();
					if (!result.isNullable()) result = GmlTypeDef.nullable(result);
				case "|".code:
					if ((flags & FNoEither) != 0) break;
					q.skip();
					var et = [result];
					while (q.loop) {
						var t = parseRec(q, ctx, FNoEither);
						if (t == null) return null;
						et.push(t);
						parseRec_skip(q);
						if (q.peek() == "|".code) q.skip(); else break;
					}
					result = TEither(et);
				default: break;
			}
		}
		return result;
	}
	
	/**
	 * This function is used by the linter.
	 * It forms a type name string and supports all the various linter tricks
	 * (like #import name rewriting)
	 */
	public static function readNameForLinter(self:GmlLinter):String @:privateAccess {
		var reader = self.reader;
		var seqStart = self.seqStart;
		var start = reader.pos;
		var startDepth = reader.depth;
		var typeStr:String;
		switch (self.next()) {
			case LKParOpen:
				seqStart.setTo(reader);
				var t = readNameForLinter(self);
				if (t == null) return null;
				if (self.next() != LKParClose) {
					self.readSeqStartError("Unclosed type ()");
					return null;
				}
				typeStr = '($t)';
			case LKSqbOpen: {
				typeStr = "[";
				var depth = 1;
				seqStart.setTo(reader);
				while (reader.loop) {
					switch (self.next()) {
						case LKSqbOpen:
							typeStr += "[";
							depth += 1;
						case LKSqbClose:
							typeStr += "]";
							depth -= 1;
							if (depth <= 0) break;
						default:
							typeStr += self.nextVal;
					}
				}
				if (depth > 0) {
					self.readSeqStartError("Unclosed tuple parameters");
					return null;
				}
			};
			case LKCubOpen: {
				typeStr = "{";
				var depth = 1;
				seqStart.setTo(reader);
				while (reader.loop) {
					switch (self.next()) {
						case LKCubOpen:
							typeStr += "{";
							depth += 1;
						case LKCubClose:
							typeStr += "}";
							depth -= 1;
							if (depth <= 0) break;
						default:
							typeStr += self.nextVal;
					}
				}
				if (depth > 0) {
					self.readSeqStartError("Unclosed tuple parameters");
					return null;
				}
			};
			case LKIdent, LKUndefined, LKFunction:
				typeStr = self.nextVal;
				while (self.skipIfPeek(LKDot)) {
					typeStr += ".";
					if (self.skipIfPeek(LKIdent)) {
						typeStr += self.nextVal;
					} else break;
				}
				if (self.skipIfPeek(LKLT)) {
					var depth = 1;
					typeStr += "<";
					seqStart.setTo(reader);
					while (reader.loop) {
						switch (self.next()) {
							case LKLT:
								typeStr += "<";
								depth += 1;
							case LKGT:
								typeStr += ">";
								depth -= 1;
								if (depth <= 0) break;
							case LKShr:
								if (depth == 1) {
									reader.pos--;
									typeStr += ">";
									depth = 0;
									break;
								} else {
									typeStr += ">>";
									depth -= 2;
									if (depth <= 0) break;
								}
							default:
								typeStr += self.nextVal;
						}
					}
					if (depth > 0) {
						self.readSeqStartError("Unclosed type parameters");
						return null;
					}
				}
			default: self.readExpect("a type name"); return null;
		}
		while (reader.loop) {
			switch (self.peek()) {
				case LKSqbOpen:
					self.skip();
					if (self.readCheckSkip(LKSqbClose, "a closing `]`")) return null;
					typeStr += "[]";
				case LKQMark:
					self.skip();
					typeStr += "?";
				case LKOr:
					self.skip();
					var t = readNameForLinter(self);
					if (t == null) return null;
					typeStr += "|" + t;
				default: break;
			}
		}
		return typeStr;
	}
	
	/**
	 * This function skips over a type name without really paying attention or anything.
	 * It's cheaper than the other two, but may totally miss some type errors.
	 */
	public static function skipTypeName(q:GmlReader, ?till:Int) {
		if (till == null) till = q.length;
		var start = q.pos;
		inline function rewind():Success {
			q.pos = start;
			return false;
		}
		q.skipSpaces1x(till);
		var c = q.read();
		switch (c) {
			case "(".code: // (group)
				if (!q.skipType(till)) return rewind();
				q.skipSpaces1x(till);
				if (q.read() != ")".code) return rewind();
			case "[".code: // [...tuple params]
				q.skip();
				if (!q.skipTypeParams(till, "[".code, "]".code)) return rewind();
			case "{".code: // {...fields}
				q.skip();
				if (!q.skipTypeParams(till, "{".code, "}".code)) return rewind();
			case _ if (c.isIdent0()): // name<...params>
				q.skipDotIdent1();
				start = q.pos;
				q.skipSpaces1x(till);
				if (q.peek() == "<".code) {
					q.skip();
					if (!q.skipTypeParams(till)) return rewind();
				} else q.pos = start;
			default: return rewind();
		}
		//
		start = q.pos;
		while (q.loop) {
			q.skipSpaces1x(till);
			switch (q.peek()) {
				case "[".code if (q.peek(1) == "]".code): q.skip(2);
				case "?".code: q.skip();
				case "|".code:
					q.skip();
					if (!q.skipType(till)) return rewind();
				default: break;
			}
			start = q.pos;
		}
		q.pos = start;
		return true;
	}
	
	static var cache:Dictionary<GmlType> = new Dictionary();
	public static function parse(s:String, ctx:String):GmlType {
		if (s == null) return null;
		var t = cache[s];
		if (t != null) return t;
		var q = new GmlReader(s);
		t = parseRec(q, ctx);
		q.skipSpaces0();
		if (q.loopLocal) Console.warn("Type parse warning in `"
			+ s.insert(q.pos, "¦") + '` (`$ctx`): Trailing data');
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
	var FCanAlias = 2;
}