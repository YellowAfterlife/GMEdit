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
	
	/** "ns" -> "some" -> "script" (for "ns.some")*/
	public var namespaces:Dictionary<Dictionary<String>> = new Dictionary();
	
	//
	public function new() {
		//
	}
	//
	public function add(
		long:String, short:String, kind:String, comp:AceAutoCompleteItem, ?space:String
	) {
		if (space != null) {
			var nsd = namespaces[space];
			if (nsd == null) {
				nsd = new Dictionary();
				namespaces.set(space, nsd);
			}
			nsd.set(short, kind);
			short = space + "." + short;
		} else {
			this.kind.set(short, kind);
		}
		//
		shorten.set(long, short);
		longen.set(short, long);
		//
		if (comp != null) {
			var nc = new AceAutoCompleteItem(short, comp.meta, comp.doc);
			if (nc.doc == null) nc.doc = long;
			this.comp.push(nc);
		}
	}
	//
}
