package gmx;
import gmx.SfGmx;
import js.lib.RegExp;
import parsers.GmlReader;
import tools.Aliases;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxAction {
	public static var errorText:String;
	//
	static function argumentMapper(argNode:SfGmx):GmxActionArg {
		var kind:GmxActionArgKind = argNode.findInt("kind");
		var value = argNode.children.length > 1 ? argNode.children[1].text : null;
		return { kind: kind, s: value };
	}
	public static function getGmxActionData(action:SfGmx):GmxActionData {
		inline function str(name:String) {
			return action.findText(name);
		}
		inline function int(name:String) {
			return action.findInt(name);
		}
		inline function bool(name:String) {
			return action.findInt(name) != 0;
		}
		var d:GmxActionData = {
			libid: int("libid"),
			id: int("id"),
			kind: GmxActionKind.fromInt(int("kind")),
			isQuestion: bool("isquestion"),
			exeType: GmxActionExeType.fromInt(int("exetype")),
			fn: str("functionname"),
			code: str("codestring"),
			who: bool("useapplyto") ? str("whoName") : null,
			rel: bool("userelative") ? bool("relative") : null,
			not: bool("isnot"),
		};
		var actionArgs = action.find("arguments");
		if (actionArgs != null) {
			d.args = actionArgs.findAll("argument").map(argumentMapper);
			if (d.libid == 1 && d.id == 603 && d.args[0] != null) {
				// GM:S code blocks have a trailing \r\n, unless empty
				d.args[0].s = d.args[0].s.trimTrailRn();
			}
		}
		return d;
	}
	public static function getCode(node:SfGmx):GmlCode {
		var out = GmxActionDecoder.decode(getGmxActionData(node));
		if (out != null) return out.code;
		errorText = GmxActionDecoder.errorText;
		return null;
	}
	public static function getCodeMulti(nodes:Array<SfGmx>) {
		var actions = nodes.map(getGmxActionData);
		var snip = GmxActionDecoder.decodeArray(actions);
		if (snip == null) errorText = GmxActionDecoder.errorText;
		return snip;
	}
	//
	public static function makeGmxActionBlock(d:GmxActionData):SfGmx {
		inline function s<T>(c:T, d:T):String {
			return "" + (c != null ? c : d);
		}
		var action = new SfGmx("action");
		var libid = d.libid ?? 1;
		action.addTextChild("libid", "" + libid);
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
		var args = d.args;
		if (args != null) {
			if (libid == 1 && d.id == 603 && args.length == 1 && args[0].s != "") {
				// GM:S code blocks have a trailing \r\n, unless empty
				var arg = args[0];
				args = [{ kind: arg.kind, s: arg.s + "\r\n" }];
			}
			var arguments = new SfGmx("arguments");
			action.addChild(arguments);
			for (arg in args) {
				var argument = new SfGmx("argument");
				var kind:GmxActionArgKind = arg.kind ?? Text;
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
	public static function makeCodeBlock(code:String):SfGmx {
		var action = GmxActionEncoder.encode(code);
		if (action == null) {
			errorText = GmxActionEncoder.errorText;
			return null;
		}
		return makeGmxActionBlock(action);
	}
}

typedef GmxActionData = {
	?libid:Int,
	?id:Int,
	?kind:GmxActionKind,
	?isQuestion:Bool,
	?exeType:GmxActionExeType,
	?fn:String, ?code:String,
	?who:String, ?rel:Bool, ?not:Bool,
	?args:Array<GmxActionArg>,
};
enum abstract GmxActionKind(Int) {
	var Normal = 0;
	var CubOpen = 1;
	var CubClose = 2;
	var Code = 7;
	public static inline function fromInt(i:Int):GmxActionKind {
		return cast i;
	}
	public inline function toInt():Int {
		return this;
	}
}
enum abstract GmxActionExeType(Int) {
	var None = 0;
	var Func = 1;
	var Code = 2;
	public static inline function fromInt(i:Int):GmxActionExeType {
		return cast i;
	}
	public inline function toInt():Int {
		return this;
	}
}
typedef GmxActionArg = { ?kind:GmxActionArgKind, ?s:String };
enum abstract GmxActionArgKind(Int) from Int to Int {
	var Snip = 0;
	var Text = 1;
	var Script = 9;
}