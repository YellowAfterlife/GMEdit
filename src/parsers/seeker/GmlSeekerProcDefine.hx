package parsers.seeker;
import ace.extern.AceAutoCompleteItem;
import gml.GmlFuncDoc;
import gml.GmlLocals;
import gml.type.GmlTypeTemplateItem;
import parsers.GmlSeekData.GmlSeekDataNamespaceHint;
import parsers.seeker.GmlSeekerImpl;
import parsers.seeker.GmlSeekerParser;
import tools.CharCode;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerProcDefine {
	public static function procFuncLiteralRetArrow(seeker:GmlSeekerImpl) {
		var q = seeker.reader;
		if (q.loop) {
			var orig = q.pos;
			q.skipSpaces1_local();
			if (q.substr(q.pos, 4) == "/*->") {
				q.pos += 4;
				var typeStart = q.pos;
				q.skipComment();
				var typeEnd = q.pos - 2;
				q.pos = typeStart;
				if (q.skipType(typeEnd)) {
					seeker.jsDoc.returns = q.substring(typeStart, q.pos);
				} else q.pos = orig;
			} else q.pos = orig;
		}
	}
	public static function procFuncLiteralArgs(seeker:GmlSeekerImpl) {
		if (seeker.find(Par0) == "(") {
			var q = seeker.reader;
			while (q.loop) {
				var s = seeker.find(Ident | Par1);
				if (s == ")" || s == null) break;
				seeker.locals.add(s, seeker.localKind);
			}
			procFuncLiteralRetArrow(seeker);
		}
	}
	public static function proc(seeker:GmlSeekerImpl, s:String) {
		var q = seeker.reader;
		var isDefine = (s == "#define");
		var isFunc = (s == "function");
		if (isFunc && seeker.funcsAreGlobal && seeker.curlyDepth == 0) isDefine = true;
		
		var jsDoc = seeker.jsDoc;
		var curlyDepth = seeker.curlyDepth;
		var funcsAreGlobal = seeker.funcsAreGlobal;
		var isCreateEvent = seeker.isCreateEvent;
		var out = seeker.out;
		
		var fname:String;
		if (isFunc) {
			q.skipSpaces0();
			if (q.peek().isIdent0_ni()) {
				var p = q.pos;
				q.skipIdent1();
				fname = q.substring(p, q.pos);
			} else fname = null;
		} else fname = seeker.find(Ident);
		
		// early exit if it's a `x = function()` or a function-in-function
		if (isFunc && (!isDefine || fname == null)) {
			if (curlyDepth > 0 || !funcsAreGlobal) {
				if (!funcsAreGlobal && curlyDepth == 0 && fname != null) {
					// function name() in events
					GmlSeekerProcField.addInstVar(seeker, fname);
				}
				seeker.subLocalDepth = curlyDepth;
				seeker.localKind = "sublocal";
			}
			if (seeker.isCreateEvent && curlyDepth == 0 && fname != null) {
				var argsStart = q.pos;
				procFuncLiteralArgs(seeker);
				var args:String = q.substring(argsStart, q.pos).trimBoth();
				var argTypes = null;
				if (jsDoc.args != null) {
					args = "(" + jsDoc.args.join(", ") + ")";
					argTypes = jsDoc.typesFlush(null, fname);
					jsDoc.args = null;
					jsDoc.types = null;
				}
				if (jsDoc.returns != null) {
					args += GmlFuncDoc.retArrow + jsDoc.returns;
					jsDoc.returns = null;
				}
				//
				s = seeker.find(Line | Cub0 | Ident | Colon);
				var isConstructor = (s == ":" || s == "constructor");
				//
				GmlSeekerProcField.addFieldHint(seeker, isConstructor, seeker.getObjectName(), true, fname, args, null, null, argTypes, true);
			} else procFuncLiteralArgs(seeker);
			jsDoc.reset(false); // discard any collected JSDoc
			return;
		}
		
		if (isFunc) {
			// soft flush so that JSDocs prior to declaration can apply
			seeker.doc = null;
			seeker.docIsAutoFunc = false;
		} else seeker.flushDoc();
		
		var main = fname;
		seeker.main = main;
		if (jsDoc.isInterface && jsDoc.interfaceName == null) {
			jsDoc.interfaceName = main;
		}
		seeker.start = q.pos;
		seeker.sub = main;
		seeker.reader.row = isFunc ? -1 : 0;
		seeker.setLookup(main, true, "asset.script");
		var locals = new GmlLocals(main);
		seeker.locals = locals;
		out.locals.set(main, locals);
		
		if (isFunc || isDefine && seeker.version.hasScriptArgs()) { // `<keyword> name(...args)`
			s = seeker.find(isFunc ? Par0 : Line | Par0);
			if (s == "(") {
				var openPos = q.pos;
				var depth = 1;
				var awaitArgName = true;
				while (q.loop) {
					var c = q.read();
					switch (c) {
						case "(".code, "{".code, "[".code: depth++;
						case ")".code, "}".code, "]".code: if (--depth <= 0) break;
						case ",".code: if (depth == 1) awaitArgName = true;
						case '"'.code, "'".code, "@".code, "`".code: q.skipStringAuto(c, q.version);
						case "/".code: switch (q.peek()) {
							case "/".code: q.skipLine();
							case "*".code: q.skip(); q.skipComment();
							default:
						};
						case _ if (c.isIdent0()): {
							if (awaitArgName) {
								awaitArgName = false;
								q.pos--;
								var name = q.readIdent();
								locals.add(name, seeker.localKind);
							}
						};
					}
				}
				if (isDefine && jsDoc.args != null) {
					// `@param` override the parsed arguments
					var doc = GmlFuncDoc.create(main, jsDoc.args, jsDoc.rest);
					doc.argTypes = jsDoc.typesFlush(null, main);
					seeker.doc = doc;
					jsDoc.args = null;
					jsDoc.types = null;
					jsDoc.rest = false;
				} else {
					var docStart = main;
					if (jsDoc.templateItems != null) {
						docStart += GmlTypeTemplateItem.joinTemplateString(jsDoc.templateItems, true);
					}
					var doc = GmlFuncDoc.parse(docStart + q.substring(seeker.start, q.pos));
					doc.trimArgs();
					seeker.doc = doc;
				}
				procFuncLiteralRetArrow(seeker);
				if (jsDoc.returns != null) {
					seeker.doc.returnTypeString = jsDoc.returns;
					jsDoc.returns = null;
				}
				seeker.doc.templateItems = jsDoc.templateItems;
				jsDoc.templateItems = null;
				seeker.docIsAutoFunc = isFunc;
				seeker.linkDoc();
			}
		}
		//
		if (isDefine && seeker.canDefineComp) {
			seeker.mainComp = new AceAutoCompleteItem(main, "script", seeker.doc != null 
				? seeker.doc.getAcText()
				: (q.pos > seeker.start ? main + q.substring(seeker.start, q.pos) : null)
			);
			out.comps[main] = seeker.mainComp;
			out.kindList.push(main);
			out.kindMap.set(main, "asset.script");
		}
		//
		if (isFunc) {
			s = seeker.find(Line | Cub0 | Ident | Colon);
			if (s == ":" || s == "constructor") { // function A(a, b) : B(a, b) constructor
				var doc = seeker.doc;
				if (doc == null) {
					doc = GmlFuncDoc.create(main);
					seeker.doc = doc;
					seeker.linkDoc();
				}
				doc.isConstructor = true;
				doc.returnTypeString = doc.getConstructorType();
				if (s == ":") {
					s = seeker.find(Line | Cub0 | Ident);
					if (s != null && (s.fastCodeAt(0):CharCode).isIdent0_ni()) {
						doc.parentName = s;
					}
				}
				out.namespaceHints[main] = new GmlSeekDataNamespaceHint(main, doc.parentName, false);
			}
		}
	}
}