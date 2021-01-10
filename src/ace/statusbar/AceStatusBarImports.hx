package ace.statusbar;
import ace.AceStatusBar;
import ace.extern.AceRange;
import gml.GmlAPI;
import gml.GmlImports;
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
		var type:String = null;
		var iter = ctx.iter;
		var name = tk.value;
		var doc = ctx.docs[name];
		var argStart = 0;
		//
		var tk = iter.stepBackward();
		if (tk != null && tk.value == ".") {
			tk = iter.stepBackward();
			if (tk.type == "asset.object") {
				type = tk.value;
			} else if (tk.value == "other") {
				type = AceGmlTools.getOtherType({ session: ctx.session, scope: ctx.scope });
			} else if (tk.value == "self") {
				type = AceGmlTools.getSelfType({ session: ctx.session, scope: ctx.scope });
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
				type = imports.localTypes[tk.value];
			} else {
				iter.stepForward();
				tk = iter.stepForward();
			}
		} else {
			if (fnType == "localfield") {
				type = AceGmlTools.getSelfType({ session: ctx.session, scope: ctx.scope });
			}
			if (imports != null) {
				doc = AceMacro.jsOr(imports.docs[name], doc);
			}
			tk = iter.stepForward();
		}
		//
		if (type != null) {
			var step = (imports != null ? -1 : 0);
			var till = hasGlobalNamespaces ? 2 : 1;
			while (++step < till) {
				var ns = (step > 0 ? GmlAPI.gmlNamespaces[type] : imports.namespaces[type]);
				if (ns == null) continue;
				
				var td = ns.getInstDoc(name);
				if (td != null) {
					doc = td;
					if (step == 0
						&& (cast ns:GmlImportNamespace).longen.exists(name)
					) argStart = 1;
					break;
				}
			}
		} else {
			var from = AceGmlTools.skipDotExprBackwards(ctx.session, ctx.funcEnd);
			var snip = ctx.session.getTextRange(AceRange.fromPair(from, ctx.funcEnd));
			var inf = GmlLinter.getType(snip, ctx.session.gmlEditor, ctx.scope);
			doc = inf.doc;
		}
		//
		ctx.tk = tk;
		ctx.doc = doc;
		return argStart;
	}
}