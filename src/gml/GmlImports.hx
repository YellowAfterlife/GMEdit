package gml;
import gml.GmlFuncDoc;
import gml.GmlNamespace;
import tools.Dictionary;
using tools.NativeString;
import ace.AceWrap;
import ace.extern.*;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlImports {
	public static var defaultMap:Dictionary<GmlImports> = new Dictionary();
	//
	public var compList:AceAutoCompleteItems = [];
	public var compMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	
	public var kind:Dictionary<String> = new Dictionary();
	
	/** "scr_some" -> "some" */
	public var shorten:Dictionary<String> = new Dictionary();
	
	/** [global.]"longsome" -> "shortsome" */
	public var shortenGlobal:Dictionary<String> = new Dictionary();
	
	public var hasGlobal:Bool = false;
	
	/** "some" -> "scr_some" */
	public var longen:Dictionary<String> = new Dictionary();
	
	/** "renamed_enum" -> "original_enum" */
	public var longenEnum:Dictionary<String> = new Dictionary();
	
	/** namespace name -> namespace data */
	public var namespaces:Dictionary<GmlImportNamespace> = new Dictionary();
	
	public var namespaceComp:AceAutoCompleteItems = [];
	
	/** "some" -> { pre: "scr_some", ... } */
	public var docs:Dictionary<GmlFuncDoc> = new Dictionary();
	
	/** "v" -> "Some" for `var v:Some` */
	public var localTypes:Dictionary<String> = new Dictionary();
	
	//
	public function new() {
		//
	}
	//
	public function ensureNamespace(space:String):GmlImportNamespace {
		var ns = namespaces[space];
		if (ns != null) return ns;
		ns = new GmlImportNamespace(space);
		var origKind = this.kind[space];
		this.kind[space] = "namespace";
		namespaceComp.push(new AceAutoCompleteItem(space, "namespace"));
		namespaces.set(space, ns);
		var enLong:String, en:GmlEnum;
		if (origKind == "enum") {
			enLong = longen[space];
			en = GmlAPI.gmlEnums[enLong];
		} else {
			enLong = space;
			en = GmlAPI.gmlEnums[space];
		}
		if (en != null) {
			ns.isStruct = true;
			for (comp in en.compList) {
				var c = enumCompToNsComp(comp);
				ns.compStatic.addn(c);
				ns.compInst.addn(c);
			}
			for (name in en.names) {
				var full = enLong + "." + name;
				ns.longen.set(name, full);
				ns.shorten.set(full, name);
				ns.kind.set(name, "enumfield");
			}
		}
		return ns;
	}
	function enumCompToNsComp(comp:AceAutoCompleteItem):AceAutoCompleteItem {
		return new AceAutoCompleteItem(
			comp.name.substring(comp.name.indexOf(".") + 1),
			comp.meta, comp.name + " = " + comp.doc
		);
	}
	function enumCompToFullComp(comp:AceAutoCompleteItem, short:String):AceAutoCompleteItem {
		return new AceAutoCompleteItem(
			short + comp.name.substring(comp.name.indexOf(".")),
			comp.meta, comp.name + " = " + comp.doc
		);
	}
	/**
	 * 
	 * @param	long 	(e.g. "buffer_create")
	 * @param	short	(e.g. "makebuf")
	 * @param	kind 	Ace kind (e.g. "function")
	 * @param	comp 	Ace auto-completion item
	 * @param	doc  	Function doc (if available)
	 * @param	space	Namespace name
	 * @param	spaceOnly	Whether to only shorten for namespace, not globally
	 */
	public function add(
		long:String, short:String, kind:String, comp:AceAutoCompleteItem, doc:GmlFuncDoc,
		space:String, spaceOnly:Bool, cache:GmlImportsCache
	) {
		var isGlobal = long.startsWith("global.");
		//
		var ns:GmlImportNamespace, en:GmlEnum;
		var nc:AceAutoCompleteItem;
		inline function makeAliasComp():Void {
			nc = comp.makeAlias(short);
			if (nc.doc == null) nc.doc = long;
		}
		//
		if (space != null) {
			ns = ensureNamespace(space);
			ns.kind.set(short, kind);
			if (!isGlobal) {
				var c = ns.longen[short];
				if (c != null) ns.shorten.remove(c);
				ns.shorten.set(long, short);
				ns.longen.set(short, long);
			}
			if (comp != null) for (iter in 0 ... 2) {
				if (cache != null) {
					nc = cache.nsComp;
					if (nc == null) {
						makeAliasComp();
						cache.nsComp = nc;
					}
				} else makeAliasComp();
				var comps = iter > 0 ? ns.compInst : ns.compStatic;
				comps[short] = nc;
			}
			if (doc != null) {
				if (!spaceOnly) ns.docStaticMap[short] = doc;
				ns.docInstMap[short] = doc;
			}
			short = space + "." + short;
			if (spaceOnly) return;
		} else {
			this.kind.set(short, kind);
		}
		//
		if (isGlobal) { // #import global.long in short
			hasGlobal = true;
			shortenGlobal.set(long.substring(7), short);
		} else {
			shorten.set(long, short);
			if (kind == "enum") {
				en = GmlAPI.gmlEnums[long];
				if (en != null) {
					ns = namespaces[short];
					if (ns != null) ns.isStruct = true;
					if (cache != null) {
						var comps = cache.enumComps;
						var nsComps = cache.enumNsComps;
						if (comps == null) {
							comps = [];
							if (ns != null) nsComps = [];
							for (comp in en.compList) {
								comps.push(enumCompToFullComp(comp, short));
								if (ns != null) nsComps.push(enumCompToNsComp(comp));
							}
							cache.enumComps = comps;
							if (ns != null) cache.enumNsComps = nsComps;
						}
						for (comp in comps) compList.push(comp);
						if (ns != null) for (comp in nsComps) {
							ns.compInst.addn(comp);
							ns.compStatic.addn(comp);
						}
					} else for (comp in en.compList) {
						compList.push(enumCompToFullComp(comp, short));
						if (ns != null) {
							var c = enumCompToNsComp(comp);
							ns.compInst.addn(c);
							ns.compStatic.addn(c);
						}
					}
					if (ns != null) for (name in en.names) {
						var full = long + "." + name;
						var c = ns.longen[name];
						if (c != null) ns.shorten.remove(c);
						ns.longen.set(name, full);
						ns.shorten.set(full, name);
						ns.kind.set(name, "enumfield");
					}
				}
				longenEnum.set(short, long);
			}
		}
		//
		var c = longen[short];
		if (c != null) shorten.remove(c);
		longen.set(short, long);
		//
		if (doc != null) docs.set(short, doc);
		//
		if (comp != null) {
			// same - remove existing comp of same name (if any)
			nc = compMap[short];
			if (nc != null) compList.remove(nc);
			//
			if (cache != null) {
				nc = cache.comp;
				if (nc == null) {
					makeAliasComp();
					cache.comp = nc;
				}
			} else makeAliasComp();
			compMap.set(short, nc);
			compList.push(nc);
		}
	}
	public function addFieldHint(
		field:String, comp:AceAutoCompleteItem, doc:GmlFuncDoc,
		space:String, isInst:Bool, cache:GmlImportsCache
	) {
		var ns:GmlImportNamespace = ensureNamespace(space);
		ns.addFieldHint(field, isInst, comp, doc);
		if (!isInst) { // static-specific
			if (doc != null) docs.set(space + "." + field, doc);
			
			if (!compMap.exists(space)) {
				var nc = new AceAutoCompleteItem(space, "namespace", "type");
				compMap.set(space, nc);
				compList.push(nc);
			}
		}
	}
	public function removeFieldHint(space:String, isInst:Bool, field:String) {
		var ns = namespaces[space];
		if (ns == null) return;
		ns.removeFieldHint(field, isInst);
		if (!isInst) { // static-specific
			docs.remove(space + "." + field);
		}
	}
	//
}
typedef GmlImportsCache = {
	?comp:AceAutoCompleteItem,
	?nsComp:AceAutoCompleteItem,
	?enumComps:AceAutoCompleteItems,
	?enumNsComps:AceAutoCompleteItems,
}
class GmlImportNamespace extends GmlNamespace {
	/** "draw_text" in ns:"draw" -> "text" */
	public var shorten:Dictionary<String> = new Dictionary();
	
	/** "text" in ns:"draw" -> "draw_text" */
	public var longen:Dictionary<String> = new Dictionary();
	
	/**
	 * Means that the namespace is structurally complete and no extra variables can be used
	 * on local variables with this namespace type.
	 */
	public var isStruct:Bool = false;
}