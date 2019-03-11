package gml;
import ace.AceWrap;
import ace.extern.AceSession;
import tools.Dictionary;
using tools.NativeArray;

/**
 * 
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
		var session = Main.aceEditor.session;
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
	
	public function clear() {
		defs.clear();
		scopes.clear();
		length = 0;
	}
}
