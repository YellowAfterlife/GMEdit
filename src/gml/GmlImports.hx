package gml;
import tools.Dictionary;
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
	
	/** "some" -> "scr_some" */
	public var longen:Dictionary<String> = new Dictionary();
	
	/** namespace name -> namespace data */
	public var namespaces:Dictionary<GmlNamespace> = new Dictionary();
	
	/** "some" -> { pre: "scr_some", ... } */
	public var docs:Dictionary<GmlFuncDoc> = new Dictionary();
	
	//
	public function new() {
		//
	}
	//
	public function add(
		long:String, short:String, kind:String, comp:AceAutoCompleteItem, doc:GmlFuncDoc, ?space:String
	) {
		if (space != null) {
			var ns = namespaces[space];
			if (ns == null) {
				ns = new GmlNamespace();
				namespaces.set(space, ns);
			}
			ns.kind.set(short, kind);
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
		shorten.set(long, short);
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
	public var comp:AceAutoCompleteItems = [];
	public function new() {
		//
	}
}
