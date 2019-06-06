package parsers;
import gml.GmlVersion;
import tools.CharCode;
import tools.Aliases;
import tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlObjectProperties {
	public static inline var name:String = "properties";
	public static inline var header = '#event $name (no comments/etc. here are saved)';
	//
	public static function parse(code:String, v:GmlVersion, fn:GmlObjectPropertiesFn, ?vfn:GmlObjectPropertiesVarFn):ErrorText {
		var q = new GmlReader(code);
		inline function error(p:Int, s:String):ErrorText {
			return NativeString.offsetToPos(code, p).toString() + " " + s;
		}
		var state:GmlObjectPropertiesState = WantName;
		var key:String = null, type:String = null;
		var params:Array<GmlObjectPropertiesValue> = null;
		var err:ErrorText, val:GmlObjectPropertiesValue, s:String;
		//
		inline function call(v:GmlObjectPropertiesValue) {
			if (type != null) {
				err = vfn(key, type, params, v);
			} else err = fn(key, v);
		}
		while (q.loop) {
			var c = q.peek(), start:Int;
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
					start = q.pos++;
					s = null;
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
					switch (state) {
						case WantValue: {
							call(val);
							if (err != null) return error(start, err);
							state = WantName;
							key = null;
						};
						case WantParams: {
							params.push(val);
						};
						default: return error(start, "Unexpected string");
					}
				};
				case "=".code: {
					if (state == WantSet || state == WantSetOrType) {
						state = WantValue;
						q.skip();
					} else return error(q.pos, "Unexpected =");
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
					if (state == WantParams) {
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
				default: {
					if ((c.isDigit() || c == ".".code || c == "-".code) && (state == WantValue && state == WantParams)) {
						start = q.pos;
						q.skip();
						q.skipNumber();
						s = code.substring(start, q.pos);
						var f = Std.parseFloat(s);
						if (Math.isNaN(f)) return error(start, "Invalid number " + s);
						val = Number(f);
						if (state == WantParams) {
							params.push(val);
						} else {
							call(val);
							if (err != null) return error(start, err);
						}
						state = WantName;
						key = null;
					}
					else if (c.isIdent0() && (state == WantValue || state == WantName)) {
						start = q.pos++;
						while (q.loop) {
							c = q.peek();
							if (c.isIdent1()) {
								q.skip();
							} else break;
						}
						s = code.substring(start, q.pos);
						switch (state) {
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
							default: {
								key = s;
								type = null;
								params = null;
								state = WantSet;
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
	Ident(s:String);
}
typedef GmlObjectPropertiesFn = (key:String, val:GmlObjectPropertiesValue)->ErrorText;
typedef GmlObjectPropertiesVarFn = (name:String, type:String, params:Array<GmlObjectPropertiesValue>, val:GmlObjectPropertiesValue)->ErrorText;
private enum abstract GmlObjectPropertiesState(Int) {
	var WantName = 1;
	var WantSet;
	var WantSetOrType;
	var WantValue;
	var WantType;
	var WantParamsOrSet;
	var WantParams;
	var WantParamsComma;
}
