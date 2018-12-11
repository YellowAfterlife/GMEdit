package gml;
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
	public static var currentMap:Dictionary<GmlImports> = new Dictionary();
	//
	public var comp:AceAutoCompleteItems = [];
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
	public var namespaces:Dictionary<GmlNamespace> = new Dictionary();
	
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
	public function ensureNamespace(space:String) {
		var ns = namespaces[space];
		if (ns != null) return ns;
		ns = new GmlNamespace();
		this.kind.set(space, "namespace");
		namespaceComp.push(new AceAutoCompleteItem(space, "namespace"));
		namespaces.set(space, ns);
		var enLong:String, en:GmlEnum;
		if (this.kind[space] == "enum") {
			enLong = longen[space];
			en = GmlAPI.gmlEnums[enLong];
		} else {
			enLong = space;
			en = GmlAPI.gmlEnums[space];
		}
		if (en != null) {
			ns.isStruct = true;
			for (comp in en.compList) ns.comp.push(enumCompToNsComp(comp));
			for (name in en.names) {
				var full = enLong + "." + name;
				ns.longen.set(name, full);
				ns.shorten.set(full, name);
				ns.kind.set(name, "enumfield");
			}
		}
		return ns;
	}
	inline function enumCompToNsComp(comp:AceAutoCompleteItem):AceAutoCompleteItem {
		return new AceAutoCompleteItem(
			comp.name.substring(comp.name.indexOf(".") + 1),
			comp.meta, comp.name + " = " + comp.doc
		);
	}
	public function add(
		long:String, short:String, kind:String, comp:AceAutoCompleteItem, doc:GmlFuncDoc, ?space:String
	) {
		var isGlobal = long.startsWith("global.");
		//
		var ns:GmlNamespace, en:GmlEnum;
		var nc:AceAutoCompleteItem;
		if (space != null) {
			ns = ensureNamespace(space);
			ns.kind.set(short, kind);
			if (!isGlobal) {
				ns.shorten.set(long, short);
				ns.longen.set(short, long);
			}
			if (comp != null) {
				nc = ns.compMap[short];
				if (nc != null) ns.comp.remove(nc);
				nc = comp.makeAlias(short);
				if (nc.doc == null) nc.doc = long;
				ns.compMap.set(short, nc);
				ns.comp.push(nc);
			}
			if (doc != null) ns.docs.set(short, doc);
			short = space + "." + short;
		} else {
			this.kind.set(short, kind);
		}
		//
		if (isGlobal) {
			hasGlobal = true;
			shortenGlobal.set(long.substring(7), short);
		} else {
			shorten.set(long, short);
			if (kind == "enum") {
				en = GmlAPI.gmlEnums[long];
				if (en != null) {
					ns = namespaces[short];
					if (ns != null) ns.isStruct = true;
					for (comp in en.compList) {
						this.comp.push(new AceAutoCompleteItem(
							short + comp.name.substring(comp.name.indexOf(".")),
							comp.meta, comp.name + " = " + comp.doc
						));
						if (ns != null) ns.comp.push(enumCompToNsComp(comp));
					}
					if (ns != null) for (name in en.names) {
						var full = long + "." + name;
						ns.longen.set(name, full);
						ns.shorten.set(full, name);
					}
				}
				longenEnum.set(short, long);
			}
		}
		longen.set(short, long);
		//
		if (doc != null) docs.set(short, doc);
		//
		if (comp != null) {
			nc = compMap[short];
			if (nc != null) this.comp.remove(nc);
			nc = comp.makeAlias(short);
			if (nc.doc == null) nc.doc = long;
			this.compMap.set(short, nc);
			this.comp.push(nc);
		}
	}
	//
}
class GmlNamespace {
	public var kind:Dictionary<String> = new Dictionary();
	/** "draw_text" in ns:"draw" -> "text" */
	public var shorten:Dictionary<String> = new Dictionary();
	public var longen:Dictionary<String> = new Dictionary();
	public var comp:AceAutoCompleteItems = [];
	public var compMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	public var docs:Dictionary<GmlFuncDoc> = new Dictionary();
	
	public var isStruct:Bool = false;
	public function new() {
		//
	}
}
