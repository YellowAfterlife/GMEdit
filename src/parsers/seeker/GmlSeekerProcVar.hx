package parsers.seeker;
import parsers.seeker.GmlSeekerImpl.GmlSeeker_doLoop;
import file.kind.gml.KGmlLambdas;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.GmlLocals;
import gml.type.GmlType;
import gml.type.GmlTypeTemplateItem;
import js.lib.RegExp;
import js.html.Console;
import parsers.seeker.GmlSeekerJSDoc;
import parsers.seeker.GmlSeekerParser;
import parsers.seeker.GmlSeekerProcExpr;
import synext.GmlExtLambda;
import tools.Aliases;
import tools.CharCode;
import tools.JsTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerProcVar {
	private static var localType = new RegExp("^/\\*[ \t]*:[ \t]*(\\w+)\\*/$");
	
	public static function procLambdaIdent(seeker:GmlSeekerImpl, s:GmlName, locals:GmlLocals):Void {
		var seekData = GmlExtLambda.seekData;
		var lfLocals = seekData.locals[s];
		var project = seeker.project;
		if (lfLocals == null && project.properties.lambdaMode == Scripts) {
			//
			var rel = 'scripts/$s/$s.gml';
			var full = project.fullPath(rel);
			var lgml = try {
				project.readTextFileSync(rel);
			} catch (_:Dynamic) null;
			if (lgml == null) {
				Console.warn("Lambda missing: " + s);
				lgml = "";
			}
			//
			GmlSeeker.runSync(full, lgml, "", KGmlLambdas.inst);
			var d = GmlSeekData.map[full];
			if (d == null) {
				Console.warn("We just asked to index a lambda script and it's not there..?");
				lfLocals = new GmlLocals(s);
			} else lfLocals = d.locals[""];
			seekData.locals.set(s, lfLocals);
		}
		if (lfLocals != null) locals.addLocals(lfLocals);
	}
	
	public static function proc(seeker:GmlSeekerImpl, kind:String) {
		var q:GmlReaderExt = seeker.reader;
		var locals = seeker.locals;
		var localKind = seeker.localKind;
		var hasFunctionLiterals = seeker.hasFunctionLiterals;
		var funcsAreGlobal = seeker.funcsAreGlobal;
		var canLam = seeker.canLam;
		var isStatic = kind == "static";
		var isConstructor = seeker.doc != null && seeker.doc.isConstructor;
		var isStaticCtr = isStatic && isConstructor;
		var addStaticHint = {
			var add = q.version.hasScriptDotStatic();
			if (add) {
				if (isStaticCtr && seeker.strictStaticJSDoc) {
					if (seeker.jsDoc.isStatic) {
						seeker.jsDoc.isStatic = false;
					} else add = false;
				}
			}
			add;
		};
		while (q.loop) {
			q.skipSpaces1();
			var c:CharCode = q.peek();
			var name:String;
			switch (c) {
				case "/".code: switch (q.peek(1)) {
					case "/".code: q.skip(2); q.skipLine(); continue;
					case "*".code: q.skip(2); q.skipComment(); continue;
					default: break;
				}
				case _ if (c.isIdent0()):
					name = q.readIdent();
				default: break;
			};
			
			if (name == null) break;
			if (name == (isStatic ? "static" : "var")) { // `var var`
				name = seeker.find(Ident);
			} else if (GmlAPI.kwFlow[name]) {
				// might eat a structure but that code's broken anyway
				break;
			}
			if (!isStaticCtr) locals.add(name, localKind);
			seeker.saveReader();
			var flags = SetOp | Comma | Semico | Ident | ComBlock;
			var s = seeker.find(flags);
			if (s != null && s.startsWith("/*")) { // name/*...*/
				var mt = localType.exec(s);
				if (mt != null) {
					//locals.type.set(name, mt[1]);
				}
				s = seeker.find(flags);
			}
			function skipBalancedExpr() {
				var depth = 0;
				var exit = false;
				while (q.loop) {
					seeker.saveReader();
					s = seeker.find(Par0 | Par1 | Sqb0 | Sqb1 | Cub0 | Cub1
						| Comma | Semico | Ident);
					// EOF:
					if (s == null) {
						exit = true;
						break;
					}
					switch (s) {
						case "(", "[", "{": depth += 1;
						case ")", "]", "}": {
							depth -= 1;
							if (depth < 0) { // `if (...) { var v = ... }¦`
								// find() would decrement curlyDepth so if we're backing off
								// we need to increment it back
								if (s == "}") seeker.curlyDepth++;
								q.pos--;
								break;
							}
						};
						case ",": if (depth == 0) break;
						case ";": exit = true; break;
						default: { // ident
							if (hasFunctionLiterals && s == "function") {
								var oldLocalKind = seeker.localKind;
								if (seeker.curlyDepth > 0 || !funcsAreGlobal) {
									seeker.localKind = "sublocal";
								}
								GmlSeekerProcDefine.procFuncLiteralArgs(seeker, false);
								seeker.doLoop(seeker.curlyDepth);
								seeker.localKind = oldLocalKind;
							} else if (GmlAPI.kwFlow[s]) {
								seeker.restoreReader();
								exit = true;
								break;
							} else if (canLam && s.startsWith(GmlExtLambda.lfPrefix)) {
								procLambdaIdent(seeker, s, locals);
								continue;
							}
						};
					}
				}
				return exit;
			}
			if (s == ",") {
				// OK, next
			}
			else if (s == "=" && isStatic) {
				var oldLocalKind = seeker.localKind;
				seeker.localKind = "sublocal";
				GmlSeekerProcExpr.proc(seeker, name, true);
				
				var exprIsFunction = GmlSeekerProcExpr.isFunction;
				var args:String = GmlSeekerProcExpr.args;
				var argTypes:Array<GmlType> = GmlSeekerProcExpr.argTypes;
				var exprIsConstructor = GmlSeekerProcExpr.isConstructor;
				var templateSelf:GmlType = GmlSeekerProcExpr.templateSelf;
				var templateItems:Array<GmlTypeTemplateItem> = GmlSeekerProcExpr.templateItems;
				var fieldType:GmlType = GmlSeekerProcExpr.fieldType;
				var jsDocBeforeFunc:GmlSeekerJSDoc = null;
				static var doLoopConfig = new GmlSeeker_doLoop();
				if (exprIsFunction) {
					jsDocBeforeFunc = seeker.jsDoc.copy();
					jsDocBeforeFunc.resetInterface();
					seeker.jsDoc.reset(false);
					//
					var outerDoc = seeker.doc;
					seeker.doc = null;
					doLoopConfig.exitAtCubDepth = seeker.curlyDepth;
					doLoopConfig.storeStartEnd = true;
					seeker.doLoop(doLoopConfig);
					seeker.doc = outerDoc;
					//
					jsDocBeforeFunc.append(seeker.jsDoc);
					
					// If a constructor has a @template tag, it needs to be added to templateItems
					// on methods within it so that they know which types to replace with <T>
					if (outerDoc != null && outerDoc.templateItems != null) {
						templateSelf = GmlTypeTemplateItem.toTemplateSelf(outerDoc.templateItems);
						templateItems = GmlSeekerJSDoc.concatArrays(outerDoc .templateItems, templateItems);
					}
					//
					if (jsDocBeforeFunc.args != null) {
						args = "(" + jsDocBeforeFunc.args.join(", ") + ")";
						argTypes = jsDocBeforeFunc.typesFlush(templateItems, s);
					} else {
						//args = null;
						//argTypes = null;
					}
					if (jsDocBeforeFunc.returns != null) {
						args = GmlFuncDoc.addOrReplaceReturnType(args, jsDocBeforeFunc.returns);
					}
					seeker.jsDoc.reset(false);
				}
				
				function addFieldHint(asInst:Bool) {
					// related: GmlSeekerProcIdent
					GmlSeekerProcField.addFieldHint(seeker, exprIsConstructor, seeker.jsDoc.interfaceName,
					asInst, name, args, null, fieldType, argTypes, true);
					
					var addFieldHint_doc = GmlSeekerProcField.addFieldHint_doc;
					if (addFieldHint_doc != null) {
						
						// this adds the @params from before the function declaration:
						if (jsDocBeforeFunc != null) {
							GmlSeekerProcDoc.flushToDoc(seeker, jsDocBeforeFunc, addFieldHint_doc, false);
						}
						
						// and this adds the @params from inside the function declaration!
						GmlSeekerProcDoc.flushToDoc(seeker, seeker.jsDoc, addFieldHint_doc, true);
						
						addFieldHint_doc.procHasReturn(seeker.reader.source, doLoopConfig.start, doLoopConfig.end);
						
						// similar to GmlSeekerProcIdent
						addFieldHint_doc.lookup = {
							path: seeker.orig,
							sub: seeker.sub,
							row: 0,
						};
						addFieldHint_doc.nav = {
							ctx: name,
							ctxAfter: true,
							def: seeker.jsDoc.interfaceName,
							ctxRx: new RegExp("\\bstatic\\s+" + name + "\\s*" + "\\:?=" + "\\s*function\\b"),
						};
						if (templateSelf != null) {
							addFieldHint_doc.templateSelf = templateSelf;
							addFieldHint_doc.templateItems = templateItems;
						}
					}
				}
				if (isConstructor) addFieldHint(true);
				if (addStaticHint) addFieldHint(false);
				
				seeker.localKind = oldLocalKind;
				if (exprIsFunction) {
					seeker.jsDoc.reset(false);
					//
					q.skipSpaces1_local();
					var c = q.peek();
					if (c == ",".code) continue;
					// it's a `var f = function() {}`, what else could follow 
					break;
				}
				if (skipBalancedExpr()) break;
			}
			else if (s == "=") {
				// name = (balanced expression)[,;]
				if (skipBalancedExpr()) break;
			} else {
				// EOF or `var name something_else`
				seeker.restoreReader();
				break;
			}
		}
	}
}