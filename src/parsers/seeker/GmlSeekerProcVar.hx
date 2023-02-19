package parsers.seeker;
import file.kind.gml.KGmlLambdas;
import gml.GmlAPI;
import gml.GmlLocals;
import gml.type.GmlType;
import gml.type.GmlTypeTemplateItem;
import js.lib.RegExp;
import parsers.seeker.GmlSeekerParser;
import parsers.seeker.GmlSeekerProcExpr;
import synext.GmlExtLambda;
import tools.Aliases;
import tools.CharCode;
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
				Main.console.warn("Lambda missing: " + s);
				lgml = "";
			}
			//
			GmlSeeker.runSync(full, lgml, "", KGmlLambdas.inst);
			var d = GmlSeekData.map[full];
			if (d == null) {
				Main.console.warn("We just asked to index a lambda script and it's not there..?");
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
				var isFunction = GmlSeekerProcExpr.isFunction;
				if (isFunction) {
					seeker.doLoop(seeker.curlyDepth);
				}
				var args:String = GmlSeekerProcExpr.args;
				var argTypes:Array<GmlType> = GmlSeekerProcExpr.argTypes;
				var isConstructor = GmlSeekerProcExpr.isConstructor;
				var templateSelf:GmlType = GmlSeekerProcExpr.templateSelf;
				var templateItems:Array<GmlTypeTemplateItem> = GmlSeekerProcExpr.templateItems;
				var fieldType:GmlType = GmlSeekerProcExpr.fieldType;
				
				inline function addFieldHint(asInst:Bool) {
					GmlSeekerProcField.addFieldHint(seeker, isConstructor, seeker.jsDoc.interfaceName,
					asInst, name, args, null, fieldType, argTypes, true);
					
					var addFieldHint_doc = GmlSeekerProcField.addFieldHint_doc;
					if (templateSelf != null && addFieldHint_doc != null) {
						addFieldHint_doc.templateSelf = templateSelf;
						addFieldHint_doc.templateItems = templateItems;
					}
				}
				if (isConstructor) addFieldHint(true);
				if (addStaticHint) addFieldHint(false);
				
				seeker.localKind = oldLocalKind;
				if (isFunction) {
					q.skipSpaces1_local();
					var c = q.peek();
					if (c == ",".code) continue;
					if (c == ";".code) break;
					if (c.isIdent0()) break; // static f = function() etc = 1
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