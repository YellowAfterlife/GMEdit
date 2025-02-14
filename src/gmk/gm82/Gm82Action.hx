package gmk.gm82;

import gmx.GmxActionEncoder;
import gmx.GmxActionDecoder;
import gmx.GmxAction;
using StringTools;

class Gm82Action {
	public static var errorText:String;
	static var header = "/*\"/*'/**//* YYD ACTION\n";
	public static function preproc(eventCode:String) {
		eventCode = eventCode.replace("\r", "");
		var parts = eventCode.split(header);
		parts.shift(); // anything before the first header doesn't count
		var out = "";
		for (i => part in parts) {
			var metaEnd = part.indexOf("*/");
			var metaLines = part.substring(0, metaEnd).split("\n");
			var data:GmxActionData = {};
			for (line in metaLines) {
				var sep = line.indexOf("=");
				if (sep < 0) continue;
				var key = line.substring(0, sep);
				var val = line.substring(sep + 1);
				switch (key) {
					case "lib_id": data.libid = Std.parseInt(val);
					case "action_id": data.id = Std.parseInt(val);
					case "applies_to": data.who = val;
					case "invert": data.not = Std.parseInt(val) != 0;
					case _ if (key.startsWith("arg")): {
						if (data.args == null) data.args = [];
						var i = Std.parseInt(key.substring(3));
						data.args[i] = { kind: Text, s: val };
					};
				}
			} // meta
			inline function tail() {
				return part.substring(metaEnd + 3);
			}
			if (data.libid == 1 && data.id == 603) { // code block
				data.args = [{ kind: Text, s: tail() }];
			}
			//
			var snip = GmxActionDecoder.decode(data);
			if (snip != null) {
				if (i > 0) out += GmxActionDecoder.actionSep(snip);
				out += snip.code;
			} else {
				out += "\n";
				out += header + part;
			}
		}
		//
		return out;
	}
	
	static function makeAction(a:GmxActionData) {
		var libraryID = a.libid ?? 1;
		var actionID = a.id;
		var appliesTo = a.who;
		var invert = a.not;
		var args = a.args;
		var tail:String = null;
		//
		if (libraryID == 1) switch (actionID) {
			case 603: { // code
				tail = args[0].s;
				args = null;
			}
			case 605: { // comment
				invert = false;
			}
		}
		//
		var meta = [];
		inline function pair(key:String, val:Any) {
			meta.push('$key=$val');
		}
		inline function optPair(key:String, val:Any) {
			if (val != null) meta.push('$key=$val');
		}
		inline function optPairBool(key:String, val:Any) {
			if (val != null) meta.push('$key=' + (val ? "1" : "0"));
		}
		pair("lib_id", libraryID);
		pair("action_id", actionID);
		optPair("applies_to", appliesTo);
		optPairBool("invert", invert);
		if (args != null) for (i => arg in args) {
			pair('arg$i', arg.s ?? "");
		}
		//
		return header + meta.join("\n") + "\n*/" + (tail != null ? "\n" + tail : "");
	}
	public static function postproc(parts:Array<String>) {
		var out = [];
		for (i => part in parts) {
			part = part.replace("\r", "");
			var data = GmxActionEncoder.encode(part);
			if (data == null) return null;
			var snip = makeAction(data);
			if (snip == null) {
				errorText = GmxActionEncoder.errorText;
				return null;
			} else {
				out.push(snip);
			}
		}
		return out.join("");
	}
}