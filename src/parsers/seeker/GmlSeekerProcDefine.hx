package parsers.seeker;
import ace.extern.AceAutoCompleteItem;
import gml.GmlFuncDoc;
import gml.GmlLocals;
import gml.type.GmlTypeTemplateItem;
import parsers.GmlSeekData.GmlSeekDataNamespaceHint;
import parsers.linter.GmlLinter;
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
					var result = q.substring(typeStart, q.pos);
					seeker.jsDoc.returns = result;
					q.pos = typeEnd + 2;
					return result;
				} else q.pos = orig;
			} else q.pos = orig;
		}
		return null;
	}
	
	/** "int" for "(a, b)->int" */
	public static var procFuncLiteralArgs_returnType:String = null;
	/** "(a, b)" for "(a, b)->int" */
	public static function procFuncLiteralArgs(seeker:GmlSeekerImpl, out:Bool, ?argNames:Array<String>):String {
		if (seeker.find(Par0) != "(") {
			if (out) procFuncLiteralArgs_returnType = null;
			return null;
		}
		var q = seeker.reader;
		var start = q.pos - 1;
		var argStart = q.pos;
		var wantArgName = true;
		var depth = 1;
		while (q.loop) {
			var s = seeker.find(Ident | Par0 | Par1 | Comma);
			switch (s) {
				case null: break;
				case "(": depth++;
				case ")": if (--depth <= 0) {
					if (argNames != null) {
						argNames.push(q.substring(argStart, q.pos - 1).trimBoth());
					}
					break;
				}
				case ",":
					if (depth == 1 && !wantArgName) {
						wantArgName = true;
						if (argNames != null) {
							argNames.push(q.substring(argStart, q.pos - 1).trimBoth());
							argStart = q.pos;
						}
					}
				default:
					if (wantArgName) {
						wantArgName = false;
						seeker.locals.add(s, seeker.localKind);
					}
			}
		}
		var result = out ? q.substring(start, q.pos) : null;
		var returnType = procFuncLiteralRetArrow(seeker);
		if (out) procFuncLiteralArgs_returnType = returnType;
		return result;
	}
	static var patchMissingArgs_rx = new js.lib.RegExp("^\\s*(\\w+)(\\s*=.*)$");
	static function patchMissingArgs(args:Array<String>, litArgs:Array<String>) {
		var rx = patchMissingArgs_rx;
		for (i in 0 ... litArgs.length) {
			var litArg = litArgs[i];
			var arg = args[i];
			if (arg == null) {
				args[i] = litArg;
				continue;
			}
			var mt = rx.exec(litArg);
			if (mt == null) continue;
			if (arg.contains("?") || arg.contains("=")) continue;
			var argName = arg.trimBoth();
			if (mt[1] == argName) {
				args[i] = litArg;
				continue;
			}
			args[i] += mt[2];
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
				var litArgs = GmlLinter.getOption(p->p.addMissingArgsToJSDoc) ? [] : null;
				var args = procFuncLiteralArgs(seeker, true, litArgs);
				if (args == null) args = "()";
				var argTypes = null;
				if (jsDoc.args != null) {
					// does the function itself have more named arguments than JSDoc?
					if (litArgs != null) patchMissingArgs(jsDoc.args, litArgs);
					
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
			} else procFuncLiteralArgs(seeker, false);
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
				var checkJsDocArgs = isDefine && jsDoc.args != null;
				var litArgs = checkJsDocArgs && GmlLinter.getOption(p->p.addMissingArgsToJSDoc) ? [] : null;
				var argStart = q.pos;
				while (q.loop) {
					var c = q.read();
					switch (c) {
						case "(".code, "{".code, "[".code: depth++;
						case ")".code, "}".code, "]".code: if (--depth <= 0) {
							if (litArgs != null) {
								// TODO: does this need to check if q.pos-1 > argStart ..?
								litArgs.push(q.substring(argStart, q.pos - 1).trimBoth());
							}
							break;
						}
						case ",".code: if (depth == 1 && !awaitArgName) {
							if (litArgs != null) {
								litArgs.push(q.substring(argStart, q.pos - 1).trimBoth());
								argStart = q.pos;
							}
							awaitArgName = true;
						}
						case '"'.code, "'".code, "@".code, "`".code: q.skipStringAuto(c, q.version);
						case "$".code if (q.isDqTplStart(q.version)): q.skipDqTplString(q.version);
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
				if (checkJsDocArgs) {
					if (litArgs != null) patchMissingArgs(jsDoc.args, litArgs);
					
					// `@param` override the parsed arguments
					var doc = GmlFuncDoc.create(main, jsDoc.args, jsDoc.rest);
					doc.argsAreFromJSDoc = true;
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
				GmlSeekerProcDoc.flushSelfType(seeker, seeker.doc);
				seeker.doc.templateItems = jsDoc.templateItems;
				jsDoc.templateItems = null;
				seeker.docIsAutoFunc = isFunc;
				seeker.linkDoc();
			}
		} // end of possible arguments
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