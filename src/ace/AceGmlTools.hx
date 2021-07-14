package ace;
import gml.file.GmlFile;
import ace.extern.AcePos;
import ace.extern.AceSession;
import ace.extern.AceToken;
import ace.extern.AceTokenIterator;
import ace.extern.AceTokenType;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.GmlImports;
import gml.GmlNamespace;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import parsers.GmlReaderExt;
import parsers.linter.GmlLinter;
import tools.Aliases;
import tools.Dictionary;
import tools.JsTools;
using tools.NativeString;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class AceGmlTools {
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
	
	public static inline function getSelfType(ctx:AceGmlTools_getSelfType):GmlType {
		return getSelfTypeForFile(ctx.session.gmlFile, ctx.scope);
	}
	public static inline function getSelfTypeForFile(gmlFile:GmlFile, scope:String):GmlType {
		if (gmlFile != null && (gmlFile.kind is file.kind.gml.KGmlEvents)) {
			return GmlTypeDef.simple(gmlFile.name);
		} else {
			var scopeDoc = GmlAPI.gmlDoc[JsTools.or(scope, gmlFile.name)];
			if (scopeDoc != null) {
				if (scopeDoc.isConstructor) {
					return GmlTypeDef.simple(scope);
				} else return scopeDoc.selfType;
			} else return null;
		}
	}
	
	public static inline function getOtherType(ctx:AceGmlTools_getSelfType):GmlType {
		if (ctx.scope.startsWith("collision:")) {
			return GmlTypeDef.object(ctx.scope.substring("collision:".length));
		} else return null;
	}
	
	/**
	 * `if (_) obj¦.fd = 1;` -> `if (_) ¦obj.fd = 1;`
	 * This is a token-based version of GmlCodeTools.skipDotExprBackwards
	 */
	public static function skipDotExprBackwards(session:AceSession, pos:AcePos):AcePos {
		var iter = new AceTokenIterator(session, pos.row, pos.column);
		var tmpi = iter.copy();
		var depth = 0;
		var tk:AceToken;
		if (!iter.isEOL()) iter.stepForward();
		while ((tk = iter.stepBackward()) != null) {
			var tkType = tk.type;
			switch (tkType) {
				case "text": // OK!
				case "paren.rparen", "square.paren.rparen", "curly.paren.rparen": {
					depth += tk.length;
				}
				case "paren.lparen", "square.paren.lparen": {
					depth -= tk.length;
					
					// allow `?[`:
					if (tkType.fastCodeAt(0) == "s".code) {
						tmpi.setTo(iter);
						tk = tmpi.stepBackward();
						if (tk.ncValue == "?") iter.setTo(tmpi);
					}
					
					// exit cases for ()
					if (depth <= 0) {
						tmpi.setTo(iter);
						tk = tmpi.stepBackwardNonText();
						if (tk == null) break; // `<sof>¦(` ..?
						switch (tk.type) {
							case "keyword": break;
							case "paren.rparen", "square.paren.rparen", "curly.paren.rparen": {
								// `fn()[0]¦(` and other exotic things you can do
							};
							default: if (!tk.isIdent()) break;
						}
					}
				}
				case _ if (tkType.startsWith("curly.paren.lparen")): {
					if (depth <= 0) { iter.stepForwardNonText(); break; }
					depth -= tk.length;
					if (depth <= 0) break;
				}
				case _ if (tk.isIdent()): {
					if (depth == 0 && tkType == "keyword") {
						switch (tk.value) {
							case "self", "other", "global": {}
							case "cast", "as": break;
							default: { // that's no good!
								iter.stepForwardNonText();
								break;
							}
						}
					}
					tmpi.setTo(iter);
					tk = tmpi.stepBackwardNonText();
					if (tk.ncValue == ".") {
						iter.setTo(tmpi);
						// `?.` perhaps?
						tk = tmpi.stepBackward();
						if (tk.ncValue == "?") iter.setTo(tmpi);
					} else if (depth == 0) { // identifier not preceded by a dot
						break;
					}
				}
				case _ if (depth == 0): break;
			}
		}
		tmpi.setTo(iter);
		tk = tmpi.stepBackwardNonText();
		if (tk.ncType == "keyword") switch (tk.value) {
			case "cast": return tmpi.getCurrentTokenPosition();
			case "as":
				tmpi.stepBackward();
				return skipDotExprBackwards(session, tmpi.getCurrentTokenPosition());
		}
		return iter.getCurrentTokenPosition();
	}
	
	#if !debug inline #end
	public static function findNamespace<T>(name:String, imp:GmlImports, fn:GmlNamespace->T):T {
		var step = imp != null ? -1 : 0;
		var result:T = null;
		while (++step < 2) {
			var ns = step > 0 ? GmlAPI.gmlNamespaces[name] : imp.namespaces[name];
			if (ns == null) continue;
			if (cast (result = fn(ns))) break;
		}
		return result;
	}
	
	/** Given a "Type", returns the argument info to be used when doing `var v:Type; v(` */
	public static function findSelfCallDoc(type:GmlType, imp:GmlImports):GmlFuncDoc {
		if (type == null) return null;
		var ns = type.getNamespace();
		if (ns == null) return null;
		return findNamespace(ns, imp, function(ns) {
			return ns.docInstMap[""];
		});
	}
	
	public static inline function findGlobalFuncDoc(name:String):GmlFuncDoc {
		return JsTools.orx(GmlAPI.gmlDoc[name], GmlAPI.extDoc[name], GmlAPI.stdDoc[name]);
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