package parsers.seeker;
import ace.extern.AceTokenType;
import gml.file.GmlFile;
import js.lib.RegExp;
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
			if (GmlAPI.gmlKind[s] != null || GmlAPI.extKind[s] != null) return;
		}
		
		// we'll hint top-level variable assignments in constructors and Create events:
		var isConstructorField:Bool;
		if (!isDot || isDotSelf) {
			if (seeker.jsDoc.isInterface) {
				var minDepth = seeker.hasFunctionLiterals && seeker.funcsAreGlobal ? 1 : 0;
				if (seeker.specTypeInstSubTopLevel) {
					isConstructorField = seeker.curlyDepth >= minDepth;
				} else isConstructorField = seeker.curlyDepth == minDepth;
			} else if (seeker.isCreateEvent) {
				isConstructorField = seeker.specTypeInstSubTopLevel || seeker.curlyDepth == 0;
			} else if (seeker.doc != null && seeker.doc.isConstructor) {
				if (seeker.specTypeInstSubTopLevel) {
					isConstructorField = seeker.curlyDepth >= 1;
				} else isConstructorField = seeker.curlyDepth == 1;
			} else isConstructorField = false;
			if (seeker.specTypeInstSubTopLevel && seeker.withStartsAtCurlyDepth >= 0) isConstructorField = false;
		} else isConstructorField = false;
		
		// skip if we don't have anything to do:
		var kind = GmlAPI.stdKind[s];
		var addInstField:Bool;
		if (kind != null) {
			if ((kind:AceTokenType).isKeyword()) {
				return;
			} else {
				var ns = GmlAPI.gmlNamespaces[s];
				addInstField = ns == null || ns.noTypeRef;
			}
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
		var arrayAccessors:Array<GmlSeekerProcIdent_ArrayAccessKind> = [];
		seeker.saveReader();
		while (q.loop) switch (q.read()) {
			case " ".code, "\t".code, "\r".code, "\n".code: { };
			case "=".code: skip = q.peek() == "=".code; break;
			case "[".code: // go over array indices
				var arrayLoop = true;
				do {
					var arrayAccessor:GmlSeekerProcIdent_ArrayAccessKind = AKArray;
					switch (q.peek()) {
						case "#".code: arrayAccessor = AKGrid;
						case "|".code: arrayAccessor = AKList;
						case "$".code: arrayAccessor = AKStruct;
						case "?".code:
							arrayAccessor = AKMapAny;
							q.skip();
							q.skipSpaces1();
							var c = q.peek();
							if (c.isDigit() || c == ".".code) {
								arrayAccessor = AKMapNumber;
							} else if (c == "@".code) switch (q.peek(1)) {
								case '"'.code, "'".code: arrayAccessor = AKMapString;
							}
					}
					arrayAccessors.push(arrayAccessor);
					
					var sqbDepth = 1;
					while (q.loop) { // read until and past closing bracket
						while (q.loop) {
							if (q.skipCommon_inline() >= 0) {
								
							} else switch (q.read()) {
								case "[".code: sqbDepth++;
								case "]".code:
									if (--sqbDepth <= 0) {
										q.skipSpaces1();
										arrayLoop = q.skipIfEquals("[".code);
										break;
									}
								case ",".code: {
									if (arrayAccessor == AKArray) {
										arrayAccessor = AKArray2d;
										arrayAccessors.push(AKArray);
									}
								}
							}
						}
						q.skipSpaces1();
						if (!q.skipIfEquals("[".code)) break;
					}
				} while (arrayLoop && q.loop);
				
				if (q.skipIfEquals("=".code)) {
					skip = q.peek() == "=".code;
				} else skip = true;
				break;
			/*case ":".code: {
				// todo: I don't remember what this is supposed to be
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
			};*/
			default: skip = true; break;
		}
		if (skip) { seeker.restoreReader(); return; }
		
		// that's an instance variable then
		if (addInstField) GmlSeekerProcField.addInstVar(seeker, s);
		
		//
		if (isConstructorField) {
			GmlSeekerProcExpr.proc(seeker, s);
			var args:String = GmlSeekerProcExpr.args;
			var argTypes:Array<GmlType> = GmlSeekerProcExpr.argTypes;
			var isConstructor = GmlSeekerProcExpr.isConstructor;
			var templateSelf:GmlType = GmlSeekerProcExpr.templateSelf;
			var templateItems:Array<GmlTypeTemplateItem> = GmlSeekerProcExpr.templateItems;
			var fieldType:GmlType = GmlSeekerProcExpr.fieldType;
			
			// when we have code like `arr[i] = 0`, we want `arr` to be `int[]`, not just `int`
			var arrayAccInd = arrayAccessors.length;
			while (--arrayAccInd >= 0) {
				switch (arrayAccessors[arrayAccInd]) {
					case AKArray: fieldType = GmlTypeDef.arrayOf(fieldType);
					case AKStruct: fieldType = GmlTypeDef.parse("struct");
					case AKList: fieldType = GmlTypeDef.listOf(fieldType);
					case AKGrid: fieldType = GmlTypeDef.gridOf(fieldType);
					case AKMapAny: fieldType = GmlTypeDef.mapOf(null, fieldType);
					case AKMapNumber: fieldType = GmlTypeDef.mapOf(GmlTypeDef.number, fieldType);
					case AKMapString: fieldType = GmlTypeDef.mapOf(GmlTypeDef.string, fieldType);
					default:
				}
			}
			GmlSeekerProcField.addFieldHint(seeker, isConstructor, seeker.jsDoc.interfaceName, true, s, args, null, fieldType, argTypes, true);
			var addFieldHint_doc = GmlSeekerProcField.addFieldHint_doc;
			if (addFieldHint_doc != null) {
				// similar to GmlSeekerProcVar
				var nav:GmlFileNav = {
					ctx: s,
					ctxAfter: true,
					ctxRx: new RegExp("\\b" + s + "\\s*" + "\\:?=" + "\\s*function\\b"),
				};
				if (seeker.isCreateEvent) {
					nav.def = seeker.jsDoc.interfaceName ?? "create";
				} else {
					nav.def = seeker.jsDoc.interfaceName;
				}
				addFieldHint_doc.lookup = {
					path: seeker.orig,
					sub: seeker.sub,
					row: 0,
				};
				addFieldHint_doc.nav = nav;
				if (templateSelf != null) {
					addFieldHint_doc.templateSelf = templateSelf;
					addFieldHint_doc.templateItems = templateItems;
				}
			}
		}
		seeker.restoreReader();
	}
}
enum abstract GmlSeekerProcIdent_ArrayAccessKind(Int) {
	var AKArray;
	var AKArray2d; // marks that we already handled a `,`
	var AKStruct;
	var AKList;
	var AKGrid;
	var AKMapAny;
	var AKMapNumber;
	var AKMapString;
}