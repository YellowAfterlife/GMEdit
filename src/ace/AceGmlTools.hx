package ace;
import ace.extern.AcePos;
import ace.extern.AceSession;
import ace.extern.AceToken;
import ace.extern.AceTokenIterator;
import ace.extern.AceTokenType;
import tools.Dictionary;
import tools.JsTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class AceGmlTools {
	public static function isBlank(tokenType:AceTokenType):Bool {
		var tt:String = tokenType;
		switch (tt) {
			case "text": return true;
			case _ if (tt.contains("comment")): return true;
			default: return false;
		}
	}
	public static var keywordContextKind:Dictionary<AceGmlContextKind> = (function() {
		var r = new Dictionary();
		// operators:
		for (s in ["and", "or", "xor", "not", "div", "mod"]) r[s] = Expr;
		// branching:
		for (s in ["if", "while", "until", "repeat", "switch", "return"]) r[s] = Expr;
		// misc:
		for (s in ["case", "throw"]) r[s] = Expr;
		// statements:
		for (s in ["else", "try", "do"]) r[s] = Statement;
		// single-keyword statements (meaning that the next thing is a statement too):
		for (s in ["exit", "break", "continue"]) r[s] = Statement;
		//
		return r;
	})();
	public static function getContextKind(session:AceSession, pos:AcePos):AceGmlContextKind {
		var it = new AceTokenIterator(session, pos.row, pos.column);
		var tk:AceToken;
		while ((tk = it.stepBackward()) != null) {
			var tt:String = tk.type;
			if (isBlank(tt)) continue;
			switch (tt) {
				case "keyword": return JsTools.or(keywordContextKind[tk.value], Unknown);
				case "eventname", "eventkeyname": return Statement;
				default:
			}
			//
			var tv = tk.value;
			switch (tv) {
				case ".": return MidExpr;
				case ";": return Statement;
				case "[", "(", ",": return Expr;
				case "{": {
					while ((tk = it.stepBackward()) != null) {
						if (isBlank(tk.type)) continue;
						tv = tk.value;
						switch (tv) {
							case "(": return Expr;
							case _ if (tv.endsWith("=")): return Expr;
							default: return Statement;
						}
					}
					return Statement;
				};
				case ")", "]", "}": return AfterExpr;
				case _ if (tv.contains("=")): return Expr;
				default:
			}
			//
			switch (tt) {
				case _ if (tt.contains("operator")): return Expr;
				default: return Unknown;
			}
		}
		return Statement;
	}
	
	public static function getSelfType(ctx:AceGmlTools_getSelfType):String {
		var gmlFile = ctx.session.gmlFile;
		if (gmlFile != null && (gmlFile.kind is file.kind.gml.KGmlEvents)) {
			return gmlFile.name;
		} else {
			var scopeDoc = gml.GmlAPI.gmlDoc[ctx.scope];
			if (scopeDoc != null && scopeDoc.isConstructor) {
				return ctx.scope;
			} else return null;
		}
	}
}
typedef AceGmlTools_getSelfType = {
	session: AceSession,
	scope: String,
}
enum abstract AceGmlContextKind(Int) {
	var Unknown = 0;
	/** if (x) ¦ */
	var Statement = 1;
	/** if (¦x) */
	var Expr = 2;
	/** a.¦b */
	var MidExpr = 2;
	/** if (x¦) */
	var AfterExpr = 3;
}