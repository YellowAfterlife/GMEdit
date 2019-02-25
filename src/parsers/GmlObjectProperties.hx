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
	public static function parse(code:String, v:GmlVersion, fn:GmlObjectPropertiesFn):ErrorText {
		var q = new GmlReader(code);
		inline function error(p:Int, s:String):ErrorText {
			return NativeString.offsetToPos(code, p).toString() + " " + s;
		}
		var state:GmlObjectPropertiesState = WantName;
		var key:String = null, err:ErrorText;
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
					switch (c) {
						case '"'.code: {
							if (v.hasStringEscapeCharacters()) {
								q.skipString2();
							} else q.skipString1('"'.code);
						};
						case "'".code: {
							if (v.hasSingleQuoteStrings()) {
								q.skipString1("'".code);
							} else return error(start, "Unexpected '");
						};
						case "`".code: {
							if (v.hasTemplateStrings()) {
								q.skipString1("`".code);
							} else return error(start, "Unexpected `");
						};
						case "@".code: {
							if (v.hasLiteralStrings()) {
								c = q.read();
								if (c == '"'.code || c == "'".code) {
									q.skipString1(c);
								} else return error(start, "Unexpected " + String.fromCharCode(c));
							} else return error(start, "Unexpected @");
						};
					}
					if (state != WantValue) return error(start, "Unexpected string");
					err = fn(key, code.substring(start, q.pos));
					if (err != null) return error(start, err);
					state = WantName;
					key = null;
				};
				case "=".code: {
					if (state == WantSet) {
						state = WantValue;
						q.skip();
					} else return error(q.pos, "Unexpected =");
				};
				default: {
					if ((c.isDigit() || c == ".".code || c == "-".code) && state == WantValue) {
						start = q.pos;
						q.skip();
						q.skipNumber();
						err = fn(key, code.substring(start, q.pos));
						if (err != null) return error(start, err);
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
						if (state == WantValue) {
							err = fn(key, code.substring(start, q.pos));
							if (err != null) return error(start, err);
							state = WantName;
							key = null;
						} else {
							key = code.substring(start, q.pos);
							state = WantSet;
						}
					}
					else return error(q.pos, "Unexpected " + String.fromCharCode(c));
				};
			}
		}
		return null;
	}
}
typedef GmlObjectPropertiesFn = (key:String, val:String)->ErrorText;
private enum abstract GmlObjectPropertiesState(Int) {
	var WantName = 1;
	var WantSet = 2;
	var WantValue = 3;
}
