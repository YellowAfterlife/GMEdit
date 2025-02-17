package synext;

import js.lib.RegExp;
import gml.GmlAPI;
import parsers.GmlReader;
import editors.EditCode;
using StringTools;
using tools.NativeString;

class GmlExtVarDeclSet extends SyntaxExtension {
	public static var inst = new GmlExtVarDeclSet();
	function new() {
		super("varDeclSet", "var name=value");
	}
	//
	static var rxGlobalVar = new RegExp("\\b" + "globalvar" + "[ \t]+" + "\\w");
	//
	static function getForLoop(q:GmlReader, varAt:Int, isPost:Bool) {
		var p = varAt;
		while (--p >= 0) {
			var c = q.get(p);
			if (c.isSpace1()) continue;
			if (!isPost) {
				return (c == "{".code && q.get(p - 1) == "(".code) ? p + 1 : -1;
			} else {
				return (c == "(".code) ? p + 1 : -1;
			}
		}
		return -1;
	}
	override function preproc(editor:EditCode, code:String):String {
		var version = GmlAPI.version;
		var hasVarDeclSet = version.config.hasVarDeclSet;
		if (hasVarDeclSet && !rxGlobalVar.test(code)) return code;
		var q = new GmlReader(code);
		//
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		//
		while (q.loopLocal) {
			if (q.skipCommon() >= 0) continue;
			var beforeVar = q.pos;
			var c = q.peek();
			var isGlobalVar;
			if (c == "v".code) {
				if (hasVarDeclSet) {
					q.skip();
					continue;
				}
				if (q.readIdent() != "var") continue;
				isGlobalVar = false;
			} else if (c == "g".code) {
				if (q.readIdent() != "globalvar") continue;
				isGlobalVar = true;
			} else {
				q.skip();
				continue;
			}
			//
			var afterVar = q.pos;
			var names = [];
			var spaces = [];
			var valid = true;
			var closed = false;
			while (q.loopLocal) {
				var beforeSp = q.pos;
				q.skipSpaces0_local();
				var afterSp = q.pos;
				//
				var name = q.readIdent();
				if (name == null) {
					valid = false;
					break;
				}
				//
				names.push(name);
				spaces.push(q.substring(beforeSp, afterSp));
				//
				c = q.read();
				if (c == ",".code) {
					// cont.
				} else if (c == ";".code) {
					q.pos--;
					closed = true;
					break;
				} else {
					valid = false;
					break;
				}
			}
			if (!valid || !closed) {
				q.pos = afterVar;
				continue;
			}
			//
			var decl = "";
			var found = 0;
			var index = 0;
			while (q.loopLocal && index < names.length) {
				if (!q.skipIfEquals(";".code)) {
					valid = false;
					break;
				}
				// `var a, b;¦ a = 1; b = 2;`
				var beforeSp = q.pos;
				q.skipSpaces0_local();
				var afterSp = q.pos;
				// `var a, b; ¦a = 1; b = 2;`
				var name = q.readIdent();
				if (name == null) {
					valid = false;
					break;
				}
				while (names[index] != name && index < names.length) {
					if (index > 0) decl += ",";
					decl += spaces[index] + names[index];
					index += 1;
				}
				if (index >= names.length) break;
				var space = spaces[index];
				//
				if (q.substring(beforeSp, afterSp) != space) {
					valid = false;
					break;
				}
				//
				if (index > 0) decl += ",";
				decl += space + names[index];
				// `var a, b; a¦ = 1; b = 2;`
				var beforeEqu = q.pos;
				q.skipSpaces0_local();
				if (q.read() != "=".code) {
					valid = false;
					break;
				}
				q.skipSpaces0_local();
				q.skipComplexExpr(editor);
				decl += q.substring(beforeEqu, q.pos);
				index += 1;
				found += 1;
			}
			if (!valid || found == 0) {
				continue;
			}
			var forAt = getForLoop(q, beforeVar, false);
			if (forAt != -1 && q.skipIfEquals("}".code)) {
				flush(forAt - 1);
				out += q.substring(forAt, afterVar) + decl;
			} else {
				flush(afterVar);
				out += decl;
			}
			start = q.pos;
		}
		//
		if (start == 0) return code;
		flush(q.length);
		return out;
	}
	//
	override function postproc(editor:EditCode, code:String):String {
		var version = GmlAPI.version;
		var hasVarDeclSet = version.config.hasVarDeclSet;
		if (hasVarDeclSet && !rxGlobalVar.test(code)) return code;
		//
		var q = new GmlReader(code);
		//
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		//
		while (q.loopLocal) {
			if (q.skipCommon() >= 0) continue;
			var beforeVar = q.pos;
			var c = q.peek();
			var isGlobalVar;
			if (c == "v".code) {
				if (hasVarDeclSet) {
					q.skip();
					continue;
				}
				if (q.readIdent() != "var") continue;
				isGlobalVar = false;
			} else if (c == "g".code) {
				if (q.readIdent() != "globalvar") continue;
				isGlobalVar = true;
			} else {
				q.skip();
				continue;
			}
			//
			var afterVar = q.pos;
			var decl = "";
			var sets = "";
			var valid = true;
			var found = 0;
			while (q.loopLocal) {
				var beforeSp = q.pos;
				q.skipSpaces0_local();
				var afterSp = q.pos;
				//
				var name = q.readIdent();
				if (name == null) {
					valid = false;
					break;
				}
				//
				var space = q.substring(beforeSp, afterSp);
				decl += space + name;
				//
				var beforeEqu = q.pos;
				q.skipSpaces0_local();
				if (q.skipIfEquals('='.code)) {
					q.skipSpaces0_local();
					q.skipComplexExpr(editor);
					sets += ";" + space + name + q.substring(beforeEqu, q.pos);
					found += 1;
				}
				//
				c = q.peek();
				if (c == ",".code) {
					decl += ",";
					q.skip();
				} else break;
			}
			if (!valid || found == 0) {
				continue;
			}
			var forAt = getForLoop(q, beforeVar, true);
			if (forAt != -1) {
				flush(forAt);
				out += "{" + q.substring(forAt, afterVar) + decl + sets + "}";
			} else {
				flush(afterVar);
				out += decl + sets;
			}
			start = q.pos;
		}
		if (start == 0) return code;
		flush(q.length);
		return out;
	}
}