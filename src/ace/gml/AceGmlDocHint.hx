package ace.gml;
import ace.AceMacro;
import ace.extern.AceHighlightRuleset;
import ace.extern.AceLangRule;
import ace.AceMacro.rxRule;
import ace.AceMacro.rxPush;
import ace.extern.AceTokenType;
import gml.GmlAPI;
import gml.GmlVersion;
import parsers.GmlReader;
import tools.Aliases;
import tools.CharCode;
import tools.Dictionary;
import tools.HighlightTools.*;
import tools.JsTools;
import ace.extern.AceLangRuleDef;
import ace.extern.AceToken;
import ace.extern.AceLangRuleDef.*;
using ace.extern.AceLangRuleDefTools;

/**
 * ...
 * @author YellowAfterlife
 */
class AceGmlDocHint {
	public static inline var ttDefault:String = "comment.doc.line";
	public static inline var ttOperator:String = "punctuation.operator";
	public static function match(value:String, state:AceLangRuleState, stack, line, row):Array<AceToken> {
		var mt = (AceMacro.jsThis:AceLangRule).splitRegex.exec(value);
		var arr = [
			rtk(ttDefault, mt[1]), // start
			rtk("comment.meta", mt[2]), // @hint
			rtk(ttDefault, mt[3]), // space
		];
		//
		var q = new GmlReader(mt[4], GmlVersion.v2);
		var start = 0;
		inline function add(t:AceTokenType, v:String):Void {
			arr.push(rtk(t, v));
		}
		inline function flush(till:Int) {
			if (till > start) add(ttDefault, q.substring(start, till));
		}
		inline function addShift(t:AceTokenType, v:String):Void {
			arr.push(rtk(t, v));
			start = q.pos;
		}
		function procSpaces():Void {
			q.skipSpaces0_local();
			if (q.pos > start) {
				add(ttDefault, q.substring(start, q.pos));
				start = q.pos;
			}
		}
		inline function procSpacesAndPeek():CharCode {
			procSpaces();
			return q.peek();
		}
		//
		function finish() {
			flush(q.length);
			return arr;
		}
		var c:CharCode;
		var typeParams:Dictionary<AceTokenType> = new Dictionary();
		function getIdentType(name:String):AceTokenType {
			return GmlAPI.gmlNamespaces.exists(name) ? "namespace" : typeParams.defget(name, "typeerror");
		}
		function procType():FoundError {
			procSpaces();
			var p = q.pos;
			c = q.read();
			switch (c) {
				case "(".code:
					addShift("paren.lparen", "(");
					if (procType()) return true;
					procSpaces();
					if (q.read() == "(".code) {
						addShift("paren.rparen", ")");
					} else return true;
				case _ if (c.isIdent0()):
					q.skipIdent1();
					var name = q.substring(p, q.pos);
					addShift(getIdentType(name), name);
					procSpaces();
					if (q.peek() == "<".code) {
						q.skip();
						addShift(ttOperator, "<");
						var closed = false;
						while (q.loopLocal) {
							if (procType()) return true;
							procSpaces();
							switch (q.peek()) {
								case ",".code, ";".code: q.skip();
								case ">".code:
									q.skip();
									addShift(ttOperator, ">");
									closed = true;
									break;
								default: return true;
							}
						}
					}
				default:
			}
			return false;
		}
		function procTypeParams():FoundError {
			q.skip();
			addShift(ttOperator, "<");
			while (q.loopLocal) {
				procSpaces();
				var typeParam = q.readIdent();
				if (typeParam == null) return true;
				addShift("variable", typeParam);
				typeParams[typeParam] = "variable";
				procSpaces();
				if (q.peek() == ":".code) {
					addShift(ttOperator, ":");
					if (procType()) return true;
					procSpaces();
				}
				var c = q.peek();
				switch (c) {
					case ";".code, ",".code:
						addShift(ttOperator, q.readChar());
					case ">".code:
						q.skip();
						addShift(ttOperator, ">");
						return false;
				}
			}
			return true;
		}
		c = q.peek();
		
		var typeStart = 0, typeEnd = 0;
		
		if (c == "{".code) { // {type}
			q.skip();
			addShift(ttOperator, "{");
			typeStart = arr.length;
			if (procType()) return finish();
			typeEnd = arr.length;
			procSpaces();
			if (q.read() == "}".code) {
				addShift(ttOperator, "}");
				c = procSpacesAndPeek();
			} else return finish();
		}
		
		var hasNamespace = c.isIdent0();
		if (hasNamespace) { // namespace
			hasNamespace = true;
			var namespaceName = q.readIdent();
			if (namespaceName == "new") {
				addShift("keyword", "new");
				procSpaces();
				namespaceName = q.readIdent();
				if (namespaceName == null) return finish();
			}
			addShift("namespace", namespaceName);
			typeParams[namespaceName] = "namespace";
			procSpaces();
			if (q.peek() == "<".code) {
				if (procTypeParams()) return finish();
			}
			c = q.peek();
		}
		
		var hasField = (c == ":".code || c == ".".code);
		if (hasField) { // :inst / .static
			addShift(ttOperator, q.readChar());
			procSpaces();
			c = q.peek();
			if (c.isIdent0()) {
				addShift("field", q.readIdent());
				c = procSpacesAndPeek();
			}
			if (q.peek() == "<".code) {
				if (procTypeParams()) return finish();
			}
			c = q.peek();
		}
		if (!hasField && !hasNamespace) return finish();
		
		{
			var i = typeStart;
			while (i < typeEnd) {
				var tk = arr[i];
				if (tk.type == "typeerror") {
					var t1 = typeParams[tk.value];
					if (t1 != null) tk.type = t1;
				}
				i += 1;
			}
		}
		
		if (c == "(".code) {
			addShift("paren.lparen", q.readChar());
			procSpaces();
			var foundArgs = (procSpacesAndPeek() == ")".code);
			if (foundArgs) {
				addShift("paren.rparen", q.readChar());
			} else while (q.loopLocal) {
				procSpaces();
				c = q.peek();
				if (c == "?".code) {
					addShift(ttOperator, q.readChar());
					c = procSpacesAndPeek();
				}
				if (c == ".".code && q.peekstr(3) == "...") {
					addShift(ttOperator, q.readChars(3));
					c = procSpacesAndPeek();
				}
				if (!c.isIdent0()) return finish();
				addShift("local", q.readIdent());
				c = procSpacesAndPeek();
				if (c == ":".code) {
					addShift(ttOperator, q.readChar());
					if (procType()) return finish();
					c = procSpacesAndPeek();
				}
				if (c == ")".code) {
					addShift("paren.rparen", q.readChar());
					foundArgs = true;
					break;
				} else if (c == ",".code) {
					addShift(ttOperator, q.readChar());
				} else return finish();
			}
			if (!foundArgs) return finish();
			if (q.peekstr(2) == "->") {
				addShift(ttOperator, q.readChars(2));
				if (procType()) return finish();
			}
		}
		
		return finish();
	}
}