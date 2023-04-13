package parsers;
import gml.GmlVersion;
import tools.CharCode;
import tools.Aliases;
import tools.NativeString;

/**
 * To consider, this is a lot of trouble for a one-off use case.
 * @author YellowAfterlife
 */
class GmlObjectProperties {
	public static inline var name:String = "properties";
	public static inline var header = '#event $name (no comments/etc. here are saved)';
	//
	public static function parse(code:String, v:GmlVersion,
		fn:GmlObjectPropertiesFn,
		?vfn:GmlObjectPropertiesVarFn,
		?ovfn:GmlObjectPropertiesOverrideFn
	):ErrorText {
		var q = new GmlReader(code);
		inline function error(p:Int, s:String):ErrorText {
			//js.Syntax.code("debugger");
			return NativeString.offsetToPos(code, p).toString() + " " + s;
		}
		var state:GmlObjectPropertiesState = WantName;
		var key:String = null, type:String = null, object:String = null;
		var params:Array<GmlObjectPropertiesValue> = null;
		var err:ErrorText, val:GmlObjectPropertiesValue, s:String;
		//
		function call(v:GmlObjectPropertiesValue) {
			if (object != null) {
				if (ovfn != null) {
					err = ovfn(object, key, v);
				} else err = null;
			} else if (type != null) {
				var guid = null;
				while (q.loop) {
					switch (q.peek()) {
						case " ".code, "\t".code, ";".code: {
							q.skip(); continue;
						};
					}; break;
				}
				if (q.peek() == "/".code && q.peek(1) == "/".code) {
					q.pos += 2;
					var start = q.pos;
					q.skipLine();
					var raw = NativeString.trimBoth(q.substring(start, q.pos));
					if (yy.YyGUID.test.test(raw)) {
						guid = cast raw;
					}
				}
				err = vfn(key, type, guid, params, v);
			} else err = fn(key, v);
		}
		var c:CharCode, start:Int;
		/// changes val
		function readString():ErrorText {
			var c = q.peek();
			start = q.pos++;
			var s = null;
			val = null;
			switch (c) {
				case '"'.code: {
					if (v.hasStringEscapeCharacters()) {
						q.skipString2();
						s = code.substring(start, q.pos);
						try {
							s = haxe.Json.parse(s);
						} catch (x:Dynamic) {
							return error(start, "Invalid string, " + x);
						}
					} else q.skipString1('"'.code);
				};
				case "'".code: {
					if (v.hasSingleQuoteStrings()) {
						q.skipString1("'".code);
					} else return error(start, "Unexpected '");
				};
				case "@".code: {
					if (v.hasLiteralStrings()) {
						start++;
						c = q.read();
						if (c == '"'.code || c == "'".code) {
							q.skipString1(c);
						} else return error(start, "Unexpected " + String.fromCharCode(c));
					} else return error(start, "Unexpected @");
				};
			}
			if (s == null) s = code.substring(start + 1, q.pos - 1);
			val = CString(s);
			return null;
		}
		while (q.loop) {
			c = q.peek();
			//
			switch (c) {
				case " ".code, "\t".code, "\r".code, "\n".code, ";".code: {
					q.skip();
				};
				case "/".code: switch (q.peek(1)) {
					case "/".code: q.pos += 2; q.skipLine();
					case "*".code: q.pos += 2; q.skipComment();
					default: return error(q.pos, "Unexpected /");
				};
				case '"'.code, "'".code, "`".code, "@".code: {
					s = readString();
					if (s != null) return s;
					switch (state) {
						case WantValue: {
							call(val);
							if (err != null) return error(start, err);
							state = WantName;
							key = null;
						};
						case WantParams: {
							params.push(val);
							state = WantParamsComma;
						};
						default: return error(start, "Unexpected string");
					}
				};
				case "#".code if (q.peek(1) == '"'.code): {
					q.skip();
					s = readString();
					if (s != null) return s;
					switch (val) {
						case CString(s): val = EString(s);
						default:
					}
					switch (state) {
						case WantValue: {
							call(val);
							if (err != null) return error(start, err);
							state = WantName;
							key = null;
						};
						case WantParams: {
							params.push(val);
							state = WantParamsComma;
						};
						default: return error(start, "Unexpected code string");
					}
				};
				case "[".code: {
					if (state != WantValue) return error(q.pos, "Unexpected [");
					start = q.pos++;
					state = WantParams;
					var vals:Array<GmlObjectPropertiesValue> = [];
					while (q.loop) {
						c = q.peek();
						switch (c) {
							case "]".code: {
								if (state != WantParamsComma) return error(q.pos, "Unexpected ]");
								q.skip();
								state = WantValue;
								break;
							};
							case ",".code: {
								if (state != WantParamsComma) return error(q.pos, "Unexpected ,");
								q.skip();
								state = WantParams;
							};
							case " ".code, "\t".code, "\r".code, "\n".code: q.skip();
							case '"'.code, "'".code, "`".code, "@".code: {
								s = readString();
								if (s != null) return s;
								vals.push(val);
								state = WantParamsComma;
							};
							default: return error(q.pos, "Unexpected " + String.fromCharCode(c));
						}
					}
					if (state != WantValue) return error(start, "Unclosed [");
					//
					val = Values(vals);
					call(val);
					if (err != null) return error(start, err);
					state = WantName;
					key = null;
				};
				case "(".code: {
					var start = ++q.pos;
					q.skipVarExpr(q.version, ')'.code);
					if (q.eof) return error(start, 'Unclosed ()');
					var val = EString(q.substring(start, q.pos++));
					switch (state) {
						case WantValue: {
							call(val);
							if (err != null) return error(start, err);
							state = WantName;
							key = null;
						};
						case WantParams: {
							params.push(val);
							state = WantParamsComma;
						};
						default: return error(start, "Unexpected code literal");
					}
				};
				case "=".code: {
					switch (state) {
						case WantSet, WantSetOrType, WantParamsOrSet: {
							state = WantValue;
							q.skip();
						};
						default: return error(q.pos, "Unexpected =");
					}
				};
				case ":".code: {
					if (state == WantSetOrType && vfn != null) {
						state = WantType;
						q.skip();
					} else return error(q.pos, "Unexpected :");
				};
				case "<".code: {
					if (state == WantParamsOrSet) {
						state = WantParams;
						params = [];
						q.skip();
					} else return error(q.pos, "Unexpected <");
				};
				case ">".code: {
					if (state == WantParamsComma) {
						state = WantSet;
						q.skip();
					} else return error(q.pos, "Unexpected >");
				};
				case ",".code: {
					if (state == WantParamsComma) {
						state = WantParams;
						q.skip();
					} else return error(q.pos, "Unexpected ,");
				};
				case ".".code: {
					switch (state) {
						case WantSetOrType: {
							state = WantObjectFieldName;
							object = key;
							key = null;
							q.skip();
						};
						default: return error(q.pos, "Unexpected .");
					}
				};
				default: {
					inline function wantIdent():Bool {
						return switch (state) {
							case WantValue, WantName, WantType,
								WantParams, WantObjectFieldName: true;
							default: false;
						}
					}
					if ((c.isDigit() || c == ".".code || c == "-".code) && (state == WantValue || state == WantParams)) {
						start = q.pos;
						q.skip();
						q.skipNumber();
						s = code.substring(start, q.pos);
						var f = Std.parseFloat(s);
						if (Math.isNaN(f)) return error(start, "Invalid number " + s);
						val = Number(f);
						if (state == WantParams) {
							params.push(val);
							state = WantParamsComma;
						} else {
							call(val);
							if (err != null) return error(start, err);
							state = WantName;
							key = null;
						}
					}
					else if (c.isIdent0() && wantIdent()) {
						start = q.pos++;
						while (q.loop) {
							c = q.peek();
							if (c.isIdent1()) {
								q.skip();
							} else break;
						}
						s = code.substring(start, q.pos);
						switch (state) {
							case WantObjectFieldName: {
								key = s;
								state = WantSet;
							};
							case WantValue: {
								val = Ident(s);
								call(val);
								if (err != null) return error(start, err);
								state = WantName;
								key = null;
							};
							case WantType: {
								type = s;
								state = WantParamsOrSet;
							};
							case WantParams: {
								params.push(Ident(s));
								state = WantParamsComma;
							};
							default: {
								key = s;
								type = null;
								params = null;
								state = WantSetOrType;
							};
						}
					}
					else return error(q.pos, "Unexpected " + String.fromCharCode(c));
				};
			}
		}
		return null;
	}
}
enum GmlObjectPropertiesValue {
	Number(f:Float);
	CString(s:String);
	EString(s:String); // #"code"
	Ident(s:String);
	Values(a:Array<GmlObjectPropertiesValue>); // array literal
}
typedef GmlObjectPropertiesFn = (key:String, val:GmlObjectPropertiesValue)->ErrorText;
typedef GmlObjectPropertiesVarFn = (name:String, type:String, guid:yy.YyGUID, params:Array<GmlObjectPropertiesValue>, val:GmlObjectPropertiesValue)->ErrorText;
typedef GmlObjectPropertiesOverrideFn = (object:String, field:String, val:GmlObjectPropertiesValue)->ErrorText;
private enum abstract GmlObjectPropertiesState(Int) {
	var WantName = 1;
	var WantSet = 2;
	var WantSetOrType = 3;
	var WantValue = 4;
	var WantType = 5;
	var WantParamsOrSet = 6;
	var WantParams = 7;
	var WantParamsComma = 8;
	var WantObjectFieldName = 9;
}
