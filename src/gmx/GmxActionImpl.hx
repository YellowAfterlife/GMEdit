package gmx;
import gmx.SfGmx;
import js.lib.RegExp;
import parsers.GmlReader;
import tools.Aliases;
import gmx.GmxAction;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxActionImpl {
	public var errorText:ErrorText;
	public function new() {
		//
	}
	//
	function getApplyTo(action:SfGmx):String {
		return action.findText("whoName");
	}
	function getLibraryID(action:SfGmx):String {
		return action.findText("libid");
	}
	function getActionID(action:SfGmx):Int {
		return Std.parseInt(action.findText("id"));
	}
	function getFunctionName(action:SfGmx):String {
		return action.findText("functionname");
	}
	function getNotFlag(action:SfGmx):Bool {
		return action.find("isnot").text == "1";
	}
	//
	function getFirstArgString(action:SfGmx):GmlCode {
		return action.find("arguments").find("argument").find("string").text;
	}
	function getArgs(action:SfGmx):Array<SfGmx> {
		return action.find("arguments").findAll("argument");
	}
	function getArgString(arg:SfGmx):GmlCode {
		return arg.find("string").text;
	}
	function getArgScript(arg:SfGmx):GmlName {
		return arg.find("script").text;
	}
	//
	public function getCode(action:SfGmx):GmlCode {
		errorText = null;
		inline function error(s:ErrorText):GmlCode {
			errorText = s;
			return null;
		}
		if (getLibraryID(action) != "1") {
			return error("Actions from user-created libraries are not supported.");
		}
		if (getApplyTo(action) != "self") {
			return error("Non-self-applied actions are not supported.");
		}
		var aid = getActionID(action);
		var a:String;
		switch (aid) {
			case 601: {
				var args = getArgs(action);
				a = "action_execute_script " + getArgScript(args[0]);
				for (i in 1 ... args.length) {
					a += ", " + getArgString(args[i]);
				}
			};
			case 603: return getFirstArgString(action);
			case 604: a = "action_inherited";
			case 605: a = "// " + getFirstArgString(action);
			case 203: a = "action_kill_object";
			case 408: a = "action_if" + (getNotFlag(action) ? "_not " : " ") + getFirstArgString(action);
			case 422: a = "{";
			case 424: a = "}";
			default: return error("DnD action #" + aid + " `"
				+ getFunctionName(action) + "` is not supported.");
		}
		return '#action $a\r\n';
	}
	
	function makeDndBlock(d:GmxActionData):SfGmx {
		inline function s<T>(c:T, d:T):String {
			return "" + (c != null ? c : d);
		}
		var action = new SfGmx("action");
		action.addTextChild("libid", s(d.libid, 1));
		action.addTextChild("id", "" + d.id);
		action.addTextChild("kind", s(d.kind, GmxActionKind.Normal));
		action.addTextChild("userelative", d.rel != null ? "-1" : "0");
		action.addTextChild("isquestion", d.isQuestion ? "-1" : "0");
		action.addTextChild("useapplyto", d.who != null ? "-1" : "0");
		action.addTextChild("exetype", s(d.exeType, Func));
		action.addTextChild("functionname", s(d.fn, ""));
		action.addTextChild("codestring", s(d.code, ""));
		action.addTextChild("whoName", s(d.who, "self"));
		action.addTextChild("relative", d.rel ? "1" : "0");
		action.addTextChild("isnot", d.not ? "1" : "0");
		if (d.args != null) {
			var arguments = new SfGmx("arguments");
			action.addChild(arguments);
			for (arg in d.args) {
				var argument = new SfGmx("argument");
				var kind:GmxActionArgKind = arg.kind;
				if (kind == null) kind = Text;
				argument.addTextChild("kind", "" + kind);
				switch (kind) {
					case Script: argument.addTextChild("script", arg.s);
					default: {
						if (arg.s != null) argument.addTextChild("string", arg.s);
					};
				}
				arguments.addChild(argument);
			}
		}
		return action;
	}
	
	function makeDndFuncBlock(id:Int, fn:String, who:String) {
		return makeDndBlock({
			id: id,
			fn: fn,
			who: who,
			exeType: Func,
		});
	}
	
	private static var rxActionPre = new RegExp("^#action\\b");
	private static var rxActionSplit = new RegExp("^(\\w+\\b|\\{|\\}|//)\\s*(.*)$");
	public function makeCodeBlock(code:GmlCode):SfGmx {
		errorText = null;
		inline function error(s:ErrorText):SfGmx {
			errorText = s;
			return null;
		}
		//
		if (!rxActionPre.test(code)) return makeDndBlock({
			id: 603,
			kind: GmxActionKind.Code,
			exeType: GmxActionExeType.Code,
			who: "self",
			args: [{ s: code }]
		});
		//
		var actData = code.substring(7).trimBoth();
		if (actData.startsWith("//")) {
			actData = actData.substring(actData.charCodeAt(2) == " ".code ? 3 : 2);
			return makeDndBlock({
				id: 605,
				kind: Normal,
				exeType: None,
				args: [{ s: actData }]
			});
		}
		//
		var actMt = rxActionSplit.exec(actData);
		if (actMt == null) return error("Action `" + code.trimRight() + "` is not supported.");
		//
		var actName = actMt[1];
		actData = actMt[2];
		inline function noArgs():SfGmx {
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
				return makeDndBlock({
					id: 601,
					fn: "action_execute_script",
					who: "self",
					args: args,
				});
			};
			case "action_inherited": {
				if (actData != "") return noArgs();
				return makeDndFuncBlock(604, "action_inherited", null);
			};
			case "action_kill_object": {
				if (actData != "") return noArgs();
				return makeDndFuncBlock(203, "action_kill_object", "self");
			};
			case "action_if", "action_if_not": {
				return makeDndBlock({
					id: 408, isQuestion: true, exeType: Func,
					fn: "action_if", who: "self",
					not: actName == "action_if_not",
					args: [{s:actData}]
				});
			};
			case "{": {
				if (actData != "") return noArgs();
				return makeDndBlock({ id: 422, kind: CubOpen });
			};
			case "}": {
				if (actData != "") return noArgs();
				return makeDndBlock({ id: 424, kind: CubClose });
			};
			default: return error("Action `" + code.trimRight() + "` is not supported.");
		}
	}
}

typedef GmxActionData = {
	?libid:Int, id:Int, ?kind:GmxActionKind,
	?isQuestion:Bool,
	?exeType:GmxActionExeType,
	?fn:String, ?code:String,
	?who:String, ?rel:Bool, ?not:Bool,
	?args:Array<GmxActionArg>,
};
@:enum abstract GmxActionKind(Int) {
	var Normal = 0;
	var CubOpen = 1;
	var CubClose = 2;
	var Code = 7;
}
@:enum abstract GmxActionExeType(Int) {
	var None = 0;
	var Func = 1;
	var Code = 2;
}
typedef GmxActionArg = { ?kind:Int, ?s:String };
@:enum abstract GmxActionArgKind(Int) from Int to Int {
	var Snip = 0;
	var Text = 1;
	var Script = 9;
}