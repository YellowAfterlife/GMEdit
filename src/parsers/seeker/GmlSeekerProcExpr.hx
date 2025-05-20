package parsers.seeker;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTemplateItem;
import parsers.GmlSeeker;
import parsers.seeker.GmlSeekerImpl;
import parsers.seeker.GmlSeekerProcDefine;
import tools.JsTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerProcExpr {
	/** "(a, b)" or "(a, b)->ret" */
	public static var args:String = null;
	public static var argTypes:Array<GmlType> = null;
	public static var isConstructor = false;
	public static var templateSelf:GmlType = null;
	public static var templateItems:Array<GmlTypeTemplateItem> = null;
	public static var fieldType:GmlType = null;
	public static var isFunction:Bool = false;
	public static function reset() {
		args = null;
		argTypes = null;
		isConstructor = false;
		templateSelf = null;
		templateItems = null;
		fieldType = null;
		isFunction = false;
	}
	public static function proc(seeker:GmlSeekerImpl, s:String, ?asStatic:Bool) {
		reset();
		//
		var q = seeker.reader;
		q.skipSpaces1();
		var c = q.peek();
		if (c == "/".code) switch (q.peek(1)) {
			case "/".code: q.skipLine(); q.skipSpaces1(); c = q.peek();
			case "*".code: q.skip(2); q.skipComment(); q.skipSpaces1(); c = q.peek();
		}
		var specTypeInst = seeker.specTypeInst;
		function procAs() {
			q.skipSpaces1_local();
			if (q.skipIfStrEquals("/*#as ")) {
				var start = q.pos;
				q.skipComment();
				var typeStr = q.substring(start, q.pos - 2);
				fieldType = GmlTypeDef.parse(typeStr, seeker.mainTop + " offset " + start);
				return true;
			} else return false;
		}
		switch (c) {
			case "[".code: // [...]
				if (specTypeInst) {
					fieldType = GmlTypeDef.anyArray;
					q.skip(); q.skipBalancedParenExpr();
					procAs();
				}
				return;
			case '"'.code: // "str"
				if (specTypeInst) fieldType = GmlTypeDef.string;
				return;
			case "'".code if (!seeker.version.hasLiteralStrings()): // 'str'
				if (specTypeInst) fieldType = GmlTypeDef.string;
				return;
			case "@".code if (seeker.version.hasLiteralStrings() && ( // @"str"/@'str'
				q.peek(1) == '"'.code || q.peek(1) == "'".code
			)):
				if (specTypeInst) fieldType = GmlTypeDef.string;
				return;
			case "-".code, "+".code: // +1/-1
				if (specTypeInst) { // maybe "-1 as X"
					fieldType = GmlTypeDef.number;
					var start = q.pos++;
					q.skipSpaces1_local();
					if (c == "-".code && q.peek().isDigit()) {
						q.skipDigits();
						if (q.skipIfEquals(".".code)) {
							q.skipDigits();
						}
						if (Std.parseFloat(q.substring(start, q.pos)) == -1) {
							procAs();
						}
					}
				}
				return;
			case _ if (c.isDigit()): // 4
				if (specTypeInst) fieldType = GmlTypeDef.number;
				return;
			case _ if (c.isIdent0()): // some
				// OK!
			default: return;
		}
		if (!c.isIdent0_ni()) return;
		// from hereafter, we know that it's an identifier
		
		var start = q.pos;
		q.skipIdent1();
		var ident = q.substring(start, q.pos);
		
		var normalIdent = false;
		switch (ident) {
			case "function":
				// OK!
				isFunction = true;
			case "undefined", "noone":
				if (specTypeInst) procAs();
				return;
			case "new" if (seeker.hasFunctionLiterals):
				if (specTypeInst) {
					q.skipSpaces1();
					var ctr = q.readIdent();
					if (ctr != null) fieldType = GmlTypeDef.simple(ctr);
				}
				return;
			case "true", "false":
				if (specTypeInst) fieldType = GmlTypeDef.bool;
				return;
			default:
				normalIdent = true;
		}
		
		if (normalIdent) {
			if (!specTypeInst) return;
			var doc = GmlAPI.stdDoc[ident];
			q.skipSpaces1_local();
			if (doc != null) {
				if (q.skipIfEquals("(".code)) {
					fieldType = doc.returnType.mapTemplateTypes([]);
					q.skipBalancedParenExpr();
				} else fieldType = doc.getFunctionType();
			} else switch (q.peek()) {
				case "\r".code, "\n".code, ";".code:
					for (_ in 0 ... 1) {
						var loopDoc = seeker.doc;
						var found = false;
						for (_ in 0 ... 128) {
							if (loopDoc == null) break;
							
							inline function copyDoc(hdoc:GmlFuncDoc):Void {
								if (hdoc == null) return;
								args = hdoc.getNamelessAcText();
								argTypes = hdoc.argTypes;
								isConstructor = hdoc.isConstructor;
								templateSelf = hdoc.templateSelf;
								templateItems = hdoc.templateItems;
							}
							
							// check for (pending) field definition inside this file
							var hint = seeker.out.fieldHints[loopDoc.name + ":" + ident];
							if (hint != null) {
								found = true;
								copyDoc(hint.doc);
								fieldType = hint.type;
								break;
							}
							
							// check for field definition in API
							var ns = GmlAPI.gmlNamespaces[loopDoc.name];
							if (ns != null && ns.instKind.exists(ident)) {
								found = true;
								copyDoc(ns.docInstMap[ident]);
								fieldType = ns.instTypes[ident];
								break;
							}
							
							var parentName = loopDoc.parentName;
							loopDoc = seeker.out.docs[parentName];
							if (loopDoc == null) loopDoc = GmlAPI.gmlDoc[parentName];
						}
						if (found) break;
						
						// standard variable
						fieldType = GmlAPI.stdTypes[ident];
						if (fieldType != null) break;
						
						// project resource
						var resType = gml.Project.current.resourceTypes[ident];
						if (resType != null) {
							fieldType = GmlTypeDef.parse(resType);
							break;
						}
					} // once
				case "(".code:
					q.skip();
					q.skipBalancedParenExpr();
				default:
			}
			procAs();
			return;
		} // normalIdent
		
		// from hereafter, we know that it's a `function`
		q.skipSpaces1();
		if (q.peek().isIdent0_ni()) {
			// though you've messed up if you did `static name = function name`
			start = q.pos;
			q.skipIdent1();
			q.skipSpaces1();
		}
		
		start = q.pos;
		if (q.read() != "(".code) return;
		
		if (asStatic) {
			// ... since we won't be going over the whole thing like with `var`
			q.pos--;
			args = GmlSeekerProcDefine.procFuncLiteralArgs(seeker, true);
		}
		else while (q.loop) {
			var c = q.peek();
			if (c == ")".code) {
				q.skip();
				break;
			} else {
				if (q.skipCommon() < 0) q.skip();
			}
		}
		
		var doc = seeker.doc;
		var jsDoc = seeker.jsDoc;
		if (jsDoc.args != null) {
			args = "(" + jsDoc.args.join(", ") + ")";
			argTypes = jsDoc.typesFlush(JsTools.nca(doc, doc.templateItems), s);
			jsDoc.args = null;
			jsDoc.types = null;
		} else if (!asStatic) {
			args = q.substring(start, q.pos);
		}
		
		var returnType:String = null;
		if (asStatic) {
			// OK!
		} else if (q.skipIfStrEquals("/*->")) {
			var p = q.pos;
			q.skipComment();
			if (q.peekstr(2, -2) == "*/") {
				returnType = q.substring(p, q.pos - 2);
			}
		}
		//
		templateItems = jsDoc.templateItems;
		jsDoc.templateItems = null;
		if (doc != null && doc.templateItems != null) {
			templateSelf = GmlTypeTemplateItem.toTemplateSelf(doc.templateItems);
			templateItems = templateItems != null
				? doc.templateItems.concat(templateItems)
				: doc.templateItems.copy();
		}
		
		if (jsDoc.returns != null) {
			args += GmlFuncDoc.retArrow + jsDoc.returns;
			jsDoc.returns = null;
		} else if (returnType != null) {
			args += GmlFuncDoc.retArrow + returnType;
		}
		
		// constructor?:
		q.skipSpaces1();
		if (q.peek() == ":".code) {
			isConstructor = true;
			// `function(...) ¦: parent(...) constructor {...}`
		} else if (q.peek() == "c".code) {
			var ctStart = q.pos;
			q.skipIdent1();
			isConstructor = q.substring(ctStart, q.pos) == "constructor";
			// `function(...) constructor¦ {...}`
		} // else `function(...) ¦{...}`
	}
}