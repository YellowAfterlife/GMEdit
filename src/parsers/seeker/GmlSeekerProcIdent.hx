package parsers.seeker;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTemplateItem;
import synext.GmlExtLambda;
import tools.JsTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerProcIdent {
	public static function proc(seeker:GmlSeekerImpl, s:String) {
		var q = seeker.reader;
		var commentLineJumps = seeker.commentLineJumps;
		
		// skip if it's a local/project/extension identifier:
		var isDotSelf = false;
		var isDot = false; {
			var dp = q.pos - s.length;
			while (--dp >= 0) {
				var jump = commentLineJumps[dp];
				if (jump != null) { dp = jump; continue; }
				var c = q.get(dp);
				if (c == ".".code) {
					isDot = true;
					while (--dp >= 0) {
						c = q.get(dp);
						if (!c.isSpace1()) break;
					}
					if (c == "f".code
						&& dp >= 3 && q.substr(dp - 3, 4) == "self"
						&& (dp == 3 || !q.get(dp - 4).isIdent1_ni())
					) isDotSelf = true;
				} else if (c.isSpace1()) {
					// OK
				} else break;
			}
		}
		
		
		if (!isDot) {
			if (seeker.locals.kind[s] != null) return;
			if (seeker.canLam && s.startsWith(GmlExtLambda.lfPrefix)) {
				GmlSeekerProcVar.procLambdaIdent(seeker, s, seeker.locals);
				return;
			}
			if (s == "with") {
				seeker.locals.hasWith = true;
				return;
			}
			if (GmlAPI.gmlKind[s] != null || GmlAPI.extKind[s] != null) return;
		}
		
		// we'll hint top-level variable assignments in constructors and Create events:
		var isConstructorField:Bool;
		if (!isDot || isDotSelf) {
			if (seeker.jsDoc.isInterface) {
				var wantDepth = seeker.hasFunctionLiterals && seeker.funcsAreGlobal ? 1 : 0;
				isConstructorField = (seeker.curlyDepth == wantDepth);
			} else if (seeker.isCreateEvent) {
				isConstructorField = seeker.curlyDepth == 0;
			} else {
				isConstructorField = seeker.curlyDepth == 1 && seeker.doc != null && seeker.doc.isConstructor;
			}
		} else isConstructorField = false;
		
		// skip if we don't have anything to do:
		var kind = GmlAPI.stdKind[s];
		var addInstField:Bool;
		if (kind != null) {
			var ns = GmlAPI.gmlNamespaces[s];
			addInstField = ns == null || ns.noTypeRef;
		} else addInstField = true;
		
		if (!addInstField && (
			// create events shouldn't hint built-ins since we'll auto-include them:
			seeker.isCreateEvent
			// other code also shouldn't hint built-ins:
			|| !isConstructorField
			// structs are allowed to override built-in variables specifically:
			|| kind != "variable"
		)) return;
		
		// skip unless it's `some =` (and no `some ==`)
		var skip = false;
		seeker.saveReader();
		while (q.loop) switch (q.read()) {
			case " ".code, "\t".code, "\r".code, "\n".code: { };
			case "=".code: skip = q.peek() == "=".code; break;
			case ":".code: {
				var swapReader = seeker.swapReader;
				var k = swapReader.pos;
				skip = true;
				while (k > 0) {
					var c = swapReader.get(k - 1);
					if (c.isIdent1()) k--; else break;
				}
				while (--k >= 0) {
					var jump = commentLineJumps[k];
					if (jump != null) { k = jump; continue; }
					switch (swapReader.get(k)) {
						case " ".code, "\t".code, "\r".code, "\n".code: { };
						case ",".code, "{".code: skip = false; break;
						default: break;
					}
				}
				break;
			};
			default: skip = true; break;
		}
		if (skip) { seeker.restoreReader(); return; }
		
		// that's an instance variable then
		if (addInstField) GmlSeekerProcField.addInstVar(seeker, s);
		
		//
		if (isConstructorField) {
			q.skipSpaces1();
			var args:String = null;
			var argTypes:Array<GmlType> = null;
			var isConstructor = false;
			var templateSelf:GmlType = null;
			var templateItems:Array<GmlTypeTemplateItem> = null;
			var fieldType:GmlType = null;
			do {
				var c = q.peek();
				var specTypeInst = seeker.specTypeInst;
				switch (c) {
					case "[".code:
						if (specTypeInst) fieldType = GmlTypeDef.anyArray;
						continue;
					case '"'.code:
						if (specTypeInst) fieldType = GmlTypeDef.string;
						continue;
					case "'".code if (!seeker.version.hasLiteralStrings()):
						if (specTypeInst) fieldType = GmlTypeDef.string;
						continue;
					case "@".code if (seeker.version.hasLiteralStrings() && (
						q.peek(1) == '"'.code || q.peek(1) == "'".code
					)):
						if (specTypeInst) fieldType = GmlTypeDef.string;
						continue;
					case "-".code, "+".code:
						if (specTypeInst) fieldType = GmlTypeDef.number;
						continue;
					case _ if (c.isDigit()):
						if (specTypeInst) fieldType = GmlTypeDef.number;
						continue;
					case _ if (c.isIdent0()):
						// OK!
					default: continue;
				}
				if (!c.isIdent0_ni()) continue;
				var start = q.pos;
				q.skipIdent1();
				var ident = q.substring(start, q.pos);
				switch (ident) {
					case "function":
						// OK!
					case "undefined", "noone":
						continue;
					case "new" if (seeker.hasFunctionLiterals):
						if (specTypeInst) {
							q.skipSpaces1();
							var ctr = q.readIdent();
							if (ctr != null) fieldType = GmlTypeDef.simple(ctr);
						}
						continue;
					case "true", "false":
						if (specTypeInst) fieldType = GmlTypeDef.bool;
						continue;
					default:
						if (specTypeInst) {
							var doc = GmlAPI.stdDoc[ident];
							q.skipSpaces1_local();
							if (doc != null) {
								if (q.peek() == "(".code) {
									fieldType = doc.returnType.mapTemplateTypes([]);
								}
							} else switch (q.peek()) {
								case "\r".code, "\n".code, ";".code:
									fieldType = GmlAPI.stdTypes[ident];
								default:
							}
						}
						continue;
				}
				q.skipSpaces1();
				if (q.peek().isIdent0_ni()) {
					// though you've messed up if you did `static name = function name`
					start = q.pos;
					q.skipIdent1();
					q.skipSpaces1();
				}
				
				start = q.pos;
				if (q.read() != "(".code) continue;
				while (q.loop) {
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
				} else args = q.substring(start, q.pos);
				
				if (q.peekstr(4) == "/*->") {
					var p = q.pos + 2;
					q.skip(4);
					q.skipComment();
					if (q.peekstr(2, -2) == "*/") {
						args += q.substring(p, q.pos - 2);
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
				}
				
				// constructor?:
				q.skipSpaces1();
				if (q.peek() == ":".code) {
					isConstructor = true;
				} else if (q.peek() == "c".code) {
					var ctStart = q.pos;
					q.skipIdent1();
					isConstructor = q.substring(ctStart, q.pos) == "constructor";
				}
			} while (false);
			GmlSeekerProcField.addFieldHint(seeker, isConstructor, seeker.jsDoc.interfaceName, true, s, args, null, fieldType, argTypes, true);
			var addFieldHint_doc = GmlSeekerProcField.addFieldHint_doc;
			if (templateSelf != null && addFieldHint_doc != null) {
				addFieldHint_doc.templateSelf = templateSelf;
				addFieldHint_doc.templateItems = templateItems;
			}
		}
		seeker.restoreReader();
	}
}