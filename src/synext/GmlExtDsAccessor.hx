package synext;

import tools.GmlCodeTools;
import parsers.GmlReader;
import js.lib.RegExp;
import gml.Project;
import editors.EditCode;
using StringTools;
using tools.NativeString;

class GmlExtDsAccessor extends SyntaxExtension {
	public static var inst = new GmlExtDsAccessor();
	//
	public function new() {
		super("ds[]", "ds[] accessors");
	}
	override function check(editor:EditCode, code:String):Bool {
		return !Project.current.version.config.hasDsAccessors;
	}
	static var rxDsFunctions = new RegExp("\\b"
		+ "ds_(?:" + [
			"list_(?:find_value|set(?:_pre)?)",
			"map_(?:find_value|set(?:_pre)?)",
			"grid_(?:get|set(?:_pre)?)",
		].join("|") + ")"
	+ "\\b");
	static function allowedOperators_init() {
		var ops = "+-*/|&^";
		var map = new Map();
		for (i in 0 ... ops.length) map[ops.charCodeAt(i)] = true;
		return map;
	}
	static var allowedOperators = allowedOperators_init();
	function preproc_sub(editor:EditCode, code:String) {
		if (!code.contains("ds_") || !rxDsFunctions.test(code)) return code;
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
			var c = q.peek();
			if (!c.isIdent0()) {
				q.skip();
				continue;
			}
			//
			var beforeFn = q.pos;
			var fn = q.readIdent();
			var acc;
			var isSet;
			var fnPre = null;
			switch (fn) {
				case "ds_list_find_value": {
					acc = "|".code;
					isSet = false;
				}
				case "ds_list_set": {
					acc = "|".code;
					isSet = true;
				}
				case "ds_list_set_post": {
					acc = "|".code;
					isSet = true;
					fnPre = "ds_list_set_pre";
				}
				//
				case "ds_map_find_value": {
					acc = "?".code;
					isSet = false;
				}
				case "ds_map_set": {
					acc = "?".code;
					isSet = true;
				}
				case "ds_map_set_post": {
					acc = "?".code;
					isSet = true;
					fnPre = "ds_map_set_pre";
				}
				//
				case "ds_grid_get": {
					acc = "#".code;
					isSet = false;
				}
				case "ds_grid_set": {
					acc = "#".code;
					isSet = true;
				}
				case "ds_grid_set_post": {
					acc = "#".code;
					isSet = true;
					fnPre = "ds_grid_set_pre";
				}
				//
				default: continue;
			}
			//
			if (!q.skipIfEquals("(".code)) continue;
			//
			if (fnPre != null) {
				if (q.readIdent() != fnPre) continue;
				if (!q.skipIfEquals("(".code)) continue;
			}
			//
			var argsStart = q.pos;
			var args = [];
			var depth = 1;
			while (q.loopLocal) {
				var c = q.read();
				switch (c) {
					case "/".code: switch (q.peek()) {
						case "/".code: q.skipLine();
						case "*".code: q.skip(); q.skipComment();
						default:
					};
					case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, q.version);
					case "(".code, "[".code, "{".code: depth++;
					case ")".code, "]".code, "}".code: if (--depth <= 0) break;
					case ",".code if (depth == 1): {
						args.push(q.substring(argsStart, q.pos - 1));
						argsStart = q.pos;
					}
					default: 
				}
			}
			if (depth > 0) continue;
			args.push(q.substring(argsStart, q.pos - 1));
			//
			var setValue = isSet ? args.pop() : null;
			var setOp = null;
			var setSpaceBefore = null;
			var setSpaceAfter = null;
			if (fnPre != null) {
				if (q.skipIfEquals(",".code)) continue;
				argsStart = q.pos;
				q.skipSpaces0_local();
				setSpaceBefore = q.substring(argsStart, q.pos);
				//
				setOp = q.read();
				if (!allowedOperators.exists(setOp)) continue;
				//
				argsStart = q.pos;
				q.skipSpaces0_local();
				setSpaceAfter = q.substring(argsStart, q.pos);
				//
				argsStart = q.pos;
				if (!q.skipBalancedParenExpr()) continue;
				args.push(q.substring(argsStart, q.pos - 1));
			} else if (isSet) {
				var origSetValue = setValue;
				setValue = setValue.trimLeft();
				setSpaceBefore = origSetValue.substring(0, origSetValue.length - setValue.length);
				setSpaceAfter = setSpaceBefore;
			}
			//
			var thing = args.shift();
			if (thing == null) continue;
			//
			flush(beforeFn);
			for (i => arg in args) args[i] = preproc_sub(editor, arg);
			out += thing + "[" + String.fromCharCode(acc) + args.join(",") + "]";
			if (isSet) {
				out += setSpaceBefore;
				if (fnPre != null) {
					out += String.fromCharCode(setOp) + "=";
				} else out += "=";
				out += setSpaceAfter + preproc_sub(editor, setValue);
			}
			start = q.pos;
		}
		//
		if (start == 0) return code;
		flush(q.length);
		return out;
	}
	override function preproc(editor:EditCode, code:String):String {
		return preproc_sub(editor, code);
	}
	//
	function postproc_sub(editor:EditCode, code:String, isSubExpr:Bool) {
		if (!code.contains("[?") && !code.contains("[|") && !code.contains("[#")) return code;
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
			var c = q.read();
			if (c != "[".code) continue;
			
			//
			var acc = q.read();
			var prefix = switch (acc) {
				case "|".code: "ds_list";
				case "?".code: "ds_map";
				case "#".code: "ds_grid";
				default: continue;
			}
			var openAt = q.pos - 2; // before the [
			
			// `map[?¦key] = value;`
			var indexStart = q.pos;
			if (!q.skipBalancedParenExpr()) break;
			var closeAt = q.pos; // after the ]
			var indexEnd = closeAt - 1;
			
			// `map[?key¦] = value;`
			var thingStart = GmlCodeTools.skipDotExprBackwards(code, openAt);
			var thing = q.substring(thingStart, openAt);
			if (thing == "") continue;
			
			// `map[?key]¦ = value;`
			q.skipSpaces0_local();
			
			// `map[?key] ¦= value;`
			var setOp;
			if (q.peek(1) == "=".code) {
				setOp = q.peek(0);
				switch (setOp) {
					case "+".code, "-".code, "*".code, "/".code,
						"&".code, "|".code, "^".code
					: q.skip(2);
					default: setOp = -1;
				}
			} else if (q.peek(0) == "=".code) {
				var isStat = !isSubExpr && GmlCodeTools.isStatementBacktrack(code, thingStart, false);
				if (isStat) {
					q.skip(1);
					setOp = "=".code;
				} else setOp = -1;
			} else setOp = -1;
			// `map[?key] =¦ value;`
			var args = postproc_sub(editor, q.substring(indexStart, indexEnd), true);
			var snip;
			if (setOp != -1) {
				var valueStart = q.pos;
				q.skipSpaces0_local();
				var setSpace = q.substring(valueStart, q.pos);
				q.skipComplexExpr(editor);
				var value = q.substring(valueStart, q.pos);
				value = postproc_sub(editor, value, true);
				if (setOp == "=".code) {
					snip = prefix + "_set("
						+ thing + ","
						+ args + "," + value
					+ ")";
				} else {
					snip = prefix + "_set_post("
						+ prefix + "_set_pre(" + thing + "," + args + ")"
						+ setSpace + String.fromCharCode(setOp) + value
					+ ")";
				}
			} else {
				var fn = acc == "#".code ? prefix + "_get" : prefix + "_find_value";
				snip = fn + "(" + thing + "," + args + ")";
			}
			//
			flush(thingStart);
			out += snip;
			start = q.pos;
		}
		//
		if (start == 0) return code;
		flush(q.length);
		return out;
	}
	override function postproc(editor:EditCode, code:String):String {
		return postproc_sub(editor, code, false);
	}
}