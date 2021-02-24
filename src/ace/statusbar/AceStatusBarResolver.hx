package ace.statusbar;
import ace.AceGmlTools;
import ace.AceStatusBar;
import gml.GmlAPI;
import gml.GmlNamespace;
import shaders.ShaderAPI;
import tools.Dictionary;
import gml.GmlFuncDoc;

/**
 * Extracts documentation item candidate(s) per token type.
 * @author YellowAfterlife
 */
class AceStatusBarResolver {
	static function initCanDocData():Dictionary<AceStatusBarDocSearch->Bool> {
		inline function flushDocs(ctx:AceStatusBarDocSearch, d:Dictionary<GmlFuncDoc>):Bool {
			ctx.docs = d;
			return d != null;
		}
		//
		var d:Dictionary<AceStatusBarDocSearch->Bool> = new Dictionary();
		d["asset.script"] = d["macro.function"] = function(c) return flushDocs(c, GmlAPI.gmlDoc);
		d["function"] = function(c) return flushDocs(c, GmlAPI.stdDoc);
		d["glsl.function"] = function(c) return flushDocs(c, ShaderAPI.glslDoc);
		d["hlsl.function"] = function(c) return flushDocs(c, ShaderAPI.hlslDoc);
		d["lambda.function"] = function(c) return flushDocs(c, c.lambdas.docs);
		d["extfunction"] = function(c) return flushDocs(c, GmlAPI.extDoc);
		d["namespace"] = function(ctx:AceStatusBarDocSearch) {
			if (ctx.imports != null) do { // show arguments for Type.create when doing `new Type`
				var ns = ctx.imports.namespaces[ctx.tk.value];
				if (ns == null) continue;
				
				var doc = ns.docStaticMap["create"];
				if (doc == null) continue;
				
				var tk = ctx.iter.copy().stepBackwardNonText();
				if (tk == null || tk.value != "new") continue;
				
				ctx.doc = doc;
				ctx.tk = tk;
				return true;
			} while (false);
			return flushDocs(ctx, GmlAPI.gmlDoc);
		}
		d["local"] = d["sublocal"] = function(ctx:AceStatusBarDocSearch) {
			// localVar() can show args from `/// @hint Type:(...)`
			var imp = ctx.imports;
			if (imp == null) return false;
			var localType = imp.localTypes[ctx.tk.value];
			if (localType == null) return false;
			ctx.type = localType;
			var doc = AceGmlTools.findSelfCallDoc(localType, imp);
			if (doc != null) {
				ctx.doc = doc;
				return true;
			} else return false;
		}
		d["field"] = function(ctx:AceStatusBarDocSearch) { // might be self.field
			ctx.docs = GmlNamespace.blank;
			return true;
		}
		d["localfield"] = function(ctx:AceStatusBarDocSearch) { // field()?
			if (AceGmlTools.getSelfType({ session: ctx.session, scope: ctx.scope }) != null) {
				ctx.docs = GmlNamespace.blank;
				return true;
			} else return false;
		}
		d["macro"] = function(ctx) { // macro->function resolution
			var m = GmlAPI.gmlMacros[ctx.tk.value];
			if (m != null) {
				var mx = m.expr;
				var doc = AceGmlTools.findGlobalFuncDoc(mx);
				if (doc != null) {
					ctx.doc = doc;
					return true;
				}
			}
			return false;
		}
		return d;
	}
}