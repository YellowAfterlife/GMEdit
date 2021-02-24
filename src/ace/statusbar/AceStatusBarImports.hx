package ace.statusbar;
import ace.AceStatusBar;
import ace.extern.AceRange;
import gml.GmlAPI;
import gml.GmlImports;
import gml.GmlNamespace;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import parsers.linter.GmlLinter;
import tools.JsTools;

/**
 * Handles various ctx.fn() mappings
 * and #import rules (e.g. grabbing a doc for draw_text from Draw.text)
 * @author YellowAfterlife
 */
class AceStatusBarImports {
	public static function procDocImport(ctx:AceStatusBarDocSearch):Int {
		var imports = ctx.imports;
		var hasGlobalNamespaces = !GmlAPI.gmlNamespaces.isEmpty();
		if (imports == null && !hasGlobalNamespaces) return 0;
		var tk = ctx.tk;
		var fnType = tk.type;
		var objType:GmlType = null;
		var iter = ctx.iter;
		var name = tk.value;
		var doc = ctx.docs[name];
		var argStart = 0;
		//
		var tk = iter.stepBackward();
		if (tk != null && tk.value == ".") {
			tk = iter.stepBackward();
			if (tk.type == "asset.object") {
				objType = GmlTypeDef.object(tk.value);
			} else if (tk.value == "other") {
				objType = AceGmlTools.getOtherType({ session: ctx.session, scope: ctx.scope });
			} else if (tk.value == "self") {
				objType = AceGmlTools.getSelfType({ session: ctx.session, scope: ctx.scope });
			} else if (tk.type == "namespace") {
				var nsName = tk.value;
				var td = null;
				
				if (imports != null) {
					td = imports.docs[nsName + "." + name];
					if (td == null) {
						var nsLocal = imports.namespaces[nsName];
						if (nsLocal != null) td = nsLocal.docStaticMap[name];
					}
				}
				
				if (td == null && hasGlobalNamespaces) {
					var nsGlobal = GmlAPI.gmlNamespaces[nsName];
					if (nsGlobal != null) td = nsGlobal.docStaticMap[name];
				}
				
				if (td != null) doc = td;
			} else if (imports != null
				&& (tk.type == "local" || tk.type == "sublocal")
				&& imports.localTypes.exists(tk.value)
			) {
				objType = imports.localTypes[tk.value];
			} else {
				iter.stepForward();
				tk = iter.stepForward();
			}
			if (objType != null) {
				var btk = iter.peekBackwardNonText();
				if (btk != null && btk.ncType == "keyword") switch (btk.value) {
					case "as", "cast": objType = null;
				}
			}
		} else {
			if (fnType == "localfield") {
				objType = AceGmlTools.getSelfType({ session: ctx.session, scope: ctx.scope });
			}
			if (imports != null) {
				doc = AceMacro.jsOr(imports.docs[name], doc);
			}
			tk = iter.stepForward();
		}
		//
		if (objType != null) {
			var tn = objType.getNamespace();
			var fieldType:GmlType = null;
			var fieldTypeText:String = null;
			if (tn != null) {
				AceGmlTools.findNamespace(tn, imports, function(ns:GmlNamespace){
					if (doc == null) {
						doc = ns.getInstDoc(name);
						if (doc != null
							&& Std.is(ns, GmlImportNamespace)
							&& (cast ns:GmlImportNamespace).longen.exists(name)
						) argStart = 1;
					}
					if (fieldTypeText == null) {
						var comp = ns.getInstCompItem(name);
						if (comp != null) fieldTypeText = comp.doc;
					}
					if (fieldType == null) {
						fieldType = ns.getInstType(name);
					}
				});
			}
			ctx.type = fieldType;
			ctx.typeText = fieldTypeText;
		} else {
			var from = AceGmlTools.skipDotExprBackwards(ctx.session, ctx.funcEnd);
			ctx.exprStart = from;
			var snip = ctx.session.getTextRange(AceRange.fromPair(from, ctx.funcEnd));
			var inf = GmlLinter.getType(snip, ctx.session.gmlEditor, ctx.scope, ctx.iter.getCurrentTokenPosition());
			doc = inf.doc;
			ctx.type = inf.type;
		}
		//
		ctx.tk = tk;
		ctx.doc = doc;
		return argStart;
	}
}