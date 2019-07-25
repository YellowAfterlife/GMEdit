package gmx;
import js.lib.RegExp;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxAction {
	public static var errorText:String;
	public static function getCode(action:SfGmx):String {
		if (action.findText("libid") != "1") {
			errorText = "Actions from user-created libraries are not supported.";
			return null;
		}
		if (action.findText("whoName") != "self") {
			errorText = "Non-self-applied actions are not supported.";
			return null;
		}
		var aid = action.findText("id");
		inline function actionArg0():String {
			return action.find("arguments").find("argument").find("string").text;
		}
		inline function actionNot():Bool {
			return action.find("isnot").text == "1";
		}
		var a:String;
		switch (Std.parseInt(aid)) {
			case 603: return actionArg0();
			case 604: a = "action_inherited";
			case 605: a = "// " + actionArg0();
			case 203: a = "action_kill_object";
			case 408: a = "action_if" + (actionNot() ? "_not " : " ") + actionArg0();
			case 422: a = "{";
			case 424: a = "}";
			default: {
				errorText = "DnD action #" + aid +
					" `" + action.findText("functionname") + "` is not supported.";
				return null;
			};
		}
		return "#action " + a + "\r\n";
	}
	static function makeDndFuncBlock(id:Int, fn:String, who:String) {
		return makeDndBlock({
			id: id,
			fn: fn,
			who: who,
			exeType: Func,
		});
	}
	static function makeDndBlock(d:GmxActionData):SfGmx {
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
				argument.addTextChild("kind", s(arg.kind, Text));
				if (arg.s != null) argument.addTextChild("string", arg.s);
				arguments.addChild(argument);
			}
		}
		return action;
	}
	private static var rxActionPre = new RegExp("^#action\\b");
	private static var rxActionSplit = new RegExp("^(\\w+\\b|\\{|\\}|//)\\s*(.*)$");
	public static function makeCodeBlock(code:String):SfGmx {
		if (rxActionPre.test(code)) {
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
			var actMt = rxActionSplit.exec(actData);
			if (actMt == null) {
				errorText = "Action `" + code.trimRight() + "` is not supported.";
				return null;
			}
			var actName = actMt[1];
			actData = actMt[2];
			inline function noArgs():SfGmx {
				errorText = "Action `" + actName + "` takes no arguments.";
				return null;
			}
			switch (actName) {
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
				default: {
					errorText = "Action `" + code.trimRight() + "` is not supported.";
					return null;
				}
			}
		}
		return makeDndBlock({
			id: 603,
			kind: GmxActionKind.Code,
			exeType: GmxActionExeType.Code,
			who: "self",
			args: [{ s: code }]
		});
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
	var Text = 1;
}
