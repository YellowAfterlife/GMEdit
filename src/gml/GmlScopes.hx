package gml;
import ace.AceWrap;
import ace.extern.AceSession;
import tools.Dictionary;
using tools.NativeArray;

/**
 * Allows to get GML scope (top-level script/event/etc. name) at a given line of an Ace Session.
 * Caches results and updates them when necessary.
 * @author YellowAfterlife
 */
@:expose("GmlScopes")
class GmlScopes {
	
	/// cached script definition per-line ("" if none there)
	public var defs:Array<String> = [];
	
	/// scope belongings per line
	public var scopes:Array<String> = [];
	
	/// Synced number of lines
	public var length:Int = 0;
	
	public var session:AceSession;
	
	public function new(session:AceSession) {
		this.session = session;
	}
	
	public function get(row:Int):String {
		var len = session.getLength();
		if (len != length) {
			length = len;
			defs.clearResize(len);
			scopes.clearResize(len);
		}
		//
		var rx = GmlAPI.scopeResetRx;
		var scope = null;
		var i = row;
		while (i >= 0) {
			scope = scopes[i];
			if (scope != null) break;
			// find definition on that line:
			var def = defs[i];
			if (def == null) {
				var res = rx.exec(session.getLine(i));
				def = res != null ? res[1] : "";
				defs[i] = def;
			}
			// if there's one, store and exit loop:
			if (def != "") {
				scope = def;
				scopes[i] = scope;
				break;
			}
			i -= 1;
		}
		//
		if (i < 0) scope = "";
		// 
		while (++i <= row) scopes[i] = scope;
		//
		return scope;
	}
	
	/** Go over the current cache and update items in case something was moved/renamed */
	public function updateOnSave():Void {
		var rx = GmlAPI.scopeResetRx;
		var currScope:String = "";
		var updateScope = false;
		for (i in 0 ... scopes.length) {
			var mt = rx.exec(session.getLine(i));
			if (mt != null) {
				currScope = mt[1];
				if (defs[i] != currScope) { // renamed or added a scope
					defs[i] = currScope;
					updateScope = true;
				} else updateScope = false;
			} else if (defs[i] != "") { // no longer has a define, but had before
				defs[i] = "";
				updateScope = true;
			}
			if (updateScope) scopes[i] = currScope;
		}
	}
	
	public function clear() {
		defs.clear();
		scopes.clear();
		length = 0;
	}
}
