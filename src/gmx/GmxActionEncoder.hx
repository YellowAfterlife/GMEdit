package gmx;
import parsers.GmlReader;
import tools.Aliases;
import gmx.GmxAction;
import js.lib.RegExp;
import tools.JsTools;
using tools.NativeString;

class GmxActionEncoder {
	public static var errorText:String;
	//
	private static var rxActionPre = new RegExp("^#action\\b");
	private static var rxActionSplit = new RegExp("^(\\w+\\b|\\{|\\}|//)\\s*(.*)$");
	//
	private static inline var rsWithCtx = "\\b(\\w+)\\b";
	private static inline var rsWithEither = '(?:\\(\\s*$rsWithCtx\\s*\\)|$rsWithCtx)';
	private static var rxActionWith = new RegExp("^#action"
		+ "\\s+" + "with\\b"
		+ "\\s*" + rsWithEither // -> context
		+ "\\s*([\\s\\S]+)"
	+ "$");
	//
	private static var rxWith = new RegExp("^#with\\b"
		+ "\\s*" + rsWithEither // -> context
		+ "\\s*([\\s\\S]*)"
	+ "$");
	public static function encode(code:String):GmxActionData {
		errorText = null;
		inline function error(s:ErrorText):GmxActionData {
			errorText = s;
			return null;
		}
		// code?
		inline function plainCode(text:String, who:String):GmxActionData {
			return {
				id: 603,
				kind: GmxActionKind.Code,
				exeType: GmxActionExeType.Code,
				who: who,
				args: [{ s: text }]
			};
		}
		var mtWith = rxWith.exec(code);
		if (mtWith != null) return plainCode(mtWith[3], JsTools.or(mtWith[1], mtWith[2]));
		if (!rxActionPre.test(code)) return plainCode(code, "self");
		//
		var who = "self";
		mtWith = rxActionWith.exec(code);
		if (mtWith != null) {
			who = JsTools.or(mtWith[1], mtWith[2]);
			code = "#action " + mtWith[3];
		}
		// comment?
		var actData = code.substring(7).trimBoth();
		if (actData.startsWith("//")) {
			actData = actData.substring(actData.charCodeAt(2) == " ".code ? 3 : 2);
			return {
				id: 605,
				kind: Normal,
				exeType: None,
				args: [{ s: actData }]
			};
		}
		//
		var actMt = rxActionSplit.exec(actData);
		if (actMt == null) return error("Action `" + code.trimRight() + "` is not supported.");
		//
		inline function makeDndFuncBlock(id:Int, fn:String, who:String):GmxActionData {
			return {
				id: id,
				fn: fn,
				who: who,
				exeType: Func,
			};
		}
		//
		var actName = actMt[1];
		actData = actMt[2];
		inline function noArgs():GmxActionData {
			return error("Action `" + actName + "` takes no arguments.");
		}
		switch (actName) {
			case "action_execute_script": {
				var args:Array<GmxActionArg> = [];
				var first = true;
				var q = new GmlReader(actData);
				var depth = 0;
				var start = 0;
				inline function flush(p:Int) {
					var s = q.substring(start, p);
					if (first) {
						first = false;
						args.push({ kind: Script, s: s });
					} else args.push({ kind: Snip, s: s });
				}
				while (q.loopLocal) {
					var n = q.skipCommon_inline();
					if (n >= 0) continue;
					var c = q.read();
					switch (c) {
						case "(".code, "[".code: depth++;
						case ")".code, "]".code: depth--;
						case ",".code: {
							if (depth == 0) {
								flush(q.pos - 1);
								if (q.peek() == " ".code) q.skip();
								start = q.pos;
							};
						};
						default: 
					}
				}
				flush(q.pos);
				return {
					id: 601,
					fn: "action_execute_script",
					who: who,
					args: args,
				};
			};
			case "action_inherited": {
				if (actData != "") return noArgs();
				return makeDndFuncBlock(604, "action_inherited", null);
			};
			case "action_kill_object": {
				if (actData != "") return noArgs();
				return makeDndFuncBlock(203, "action_kill_object", who);
			};
			case "action_if", "action_if_not": {
				return {
					id: 408, isQuestion: true, exeType: Func,
					fn: "action_if", who: who,
					not: actName == "action_if_not",
					args: [{s:actData}]
				};
			};
			case "{": {
				if (actData != "") return noArgs();
				return { id: 422, kind: CubOpen };
			};
			case "}": {
				if (actData != "") return noArgs();
				return { id: 424, kind: CubClose };
			};
			default: return error("Action `" + code.trimRight() + "` is not supported.");
		}
	}
}