package gmx;
import gml.*;
import gmx.GmxEvent;
import gmx.SfGmx;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxObject {
	public static var errorText:String;
	public static function getCode(gmx:SfGmx):String {
		var out = "";
		var errors = "";
		var objectIDs = GmlAPI.gmlAssetIDs["object"];
		for (evOuter in gmx.findAll("events")) {
			var events = evOuter.findAll("event");
			events.sort(function(a:SfGmx, b:SfGmx) {
				var atype = Std.parseInt(a.get("eventtype"));
				var btype = Std.parseInt(b.get("eventtype"));
				if (atype != btype) return atype - btype;
				//
				var aname = a.get("ename");
				var bname = b.get("ename");
				if (aname != null || bname != null) {
					var aid = objectIDs[aname];
					var bid = objectIDs[bname];
					if (aid != null && bid != null) return aid - bid;
					return untyped aname < bname ? 1 : -1;
				}
				//
				var anumb = Std.parseInt(a.get("enumb"));
				var bnumb = Std.parseInt(b.get("enumb"));
				return anumb - bnumb;
			});
			for (event in events) {
				if (out != "") out += "\n";
				var name = GmxEvent.toStringGmx(event);
				out += "#event " + name;
				var code = GmxEvent.getCode(event);
				if (code != null) {
					if (event.findAll("action").length > 0) out += "\n";
					out += code;
				} else {
					errors += "Unreadable action in " + name + "\n";
					errors += "Only self-applied code blocks are supported.\n";
				}
			}
		}
		if (errors != "") {
			errorText = errors;
			return null;
		} else return out;
	}
	
	
	public static function updateCode(gmx:SfGmx, gmlCode:String):Bool {
		var eventData = GmlEvent.parse(gmlCode, GmlVersion.v1);
		if (eventData == null) {
			errorText = GmlEvent.parseError;
			return false;
		}
		//
		var evCtr = gmx.find("events");
		if (evCtr == null) {
			evCtr = new SfGmx("events");
			gmx.addChild(evCtr);
		} else evCtr.clearChildren();
		//
		var objectIDs = GmlAPI.gmlAssetIDs["object"];
		eventData.sort(function(a, b) {
			var adata = a.data;
			var bdata = b.data;
			var atype = adata.type;
			var btype = bdata.type;
			if (atype != btype) return atype - btype;
			//
			var aname = adata.name;
			var bname = bdata.name;
			if (aname != null || bname != null) {
				var aid = objectIDs[aname];
				var bid = objectIDs[bname];
				if (aid != null && bid != null) return bid - aid;
				return untyped aname < bname ? 1 : -1;
			}
			//
			var anumb = adata.numb;
			var bnumb = bdata.numb;
			return bnumb - anumb;
		});
		//
		for (source in eventData) {
			var event = new SfGmx("event");
			var data = source.data;
			event.set("eventtype", "" + data.type);
			if (data.numb != null) event.set("enumb", "" + data.numb);
			if (data.name != null) event.set("ename", "" + data.name);
			evCtr.addChild(event);
			//
			for (gml in source.code) {
				var action = new SfGmx("action");
				action.addTextChild("libid", "1");
				action.addTextChild("id", "603");
				action.addTextChild("kind", "7");
				action.addTextChild("userelative", "0");
				action.addTextChild("isquestion", "0");
				action.addTextChild("useapplyto", "-1");
				action.addTextChild("exetype", "2");
				action.addTextChild("functionname", "");
				action.addTextChild("codestring", "");
				action.addTextChild("whoName", "self");
				action.addTextChild("relative", "0");
				action.addTextChild("isnot", "0");
				event.addChild(action);
				//
				var arguments = new SfGmx("arguments");
				action.addChild(arguments);
				var argument = new SfGmx("argument");
				argument.addTextChild("kind", "1");
				argument.addTextChild("string", gml);
				arguments.addChild(argument);
			}
		} // for (source)
		//
		//trace(gmx.toGmxString());
		return true;
	} // updateCode
}
