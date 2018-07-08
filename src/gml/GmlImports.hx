package gml;
import tools.Dictionary;
using tools.NativeString;
import ace.AceWrap;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlImports {
	public static var defaultMap:Dictionary<GmlImports> = new Dictionary();
	public static var currentMap:Dictionary<GmlImports> = new Dictionary();
	//
	public var comp:AceAutoCompleteItems = [];
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
	
	/** "some" -> { pre: "scr_some", ... } */
	public var docs:Dictionary<GmlFuncDoc> = new Dictionary();
	
	/** "v" -> "Some" for `var v:Some` */
	public var localTypes:Dictionary<String> = new Dictionary();
	
	//
	public function new() {
		//
	}
	//
	public function add(
		long:String, short:String, kind:String, comp:AceAutoCompleteItem, doc:GmlFuncDoc, ?space:String
	) {
		var isGlobal = long.startsWith("global.");
		//
		if (space != null) {
			var ns = namespaces[space];
			if (ns == null) {
				ns = new GmlNamespace();
				namespaces.set(space, ns);
			}
			ns.kind.set(short, kind);
			if (!isGlobal) {
				ns.shorten.set(long, short);
				ns.longen.set(short, long);
			}
			if (comp != null) {
				var nc = comp.makeAlias(short);
				if (nc.doc == null) nc.doc = long;
				ns.comp.push(nc);
			}
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
				var en = GmlAPI.gmlEnums[long];
				if (en != null) {
					for (comp in en.compList) {
						this.comp.push(new AceAutoCompleteItem(
							short + comp.name.substring(comp.name.indexOf(".")),
							comp.meta, comp.name + " = " + comp.doc
						));
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
			var nc = comp.makeAlias(short);
			if (nc.doc == null) nc.doc = long;
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
	public function new() {
		//
	}
}
