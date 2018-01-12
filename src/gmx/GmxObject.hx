package gmx;
import gml.*;
import electron.FileSystem;
import gmx.GmxEvent;
import gmx.SfGmx;
import haxe.io.Path;
import parsers.GmlEvent;
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
					if (event.find("action") != null) out += "\n";
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
	
	/**
	 * Attempts to update event code in specified GMX.
	 * Returns true is successful, otherwise returns false and sets errorText.
	 */
	public static function setCode(gmx:SfGmx, gmlCode:String):Bool {
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
				event.addChild(GmxAction.makeCodeBlock(gml + "\r\n"));
			}
		} // for (source)
		//
		//trace(gmx.toGmxString());
		return true;
	}
	public static function openEventInherited(full:String, edef:String):GmlFile {
		var edata = GmxEvent.fromString(edef);
		if (edata == null) return null;
		var etype:String = "" + edata.type;
		var enumb:String = edata.numb != null ? ("" + edata.numb) : null;
		var ename:String = edata.name;
		//
		var dir = Path.directory(full);
		var gmx = FileSystem.readGmxFileSync(full);
		var parent = gmx.findText("parentName");
		var tries = 1024;
		while (parent != "<undefined>" && --tries >= 0) {
			var path = Path.join([dir, parent + ".object.gmx"]);
			if (!FileSystem.existsSync(path)) return null;
			gmx = FileSystem.readGmxFileSync(path);
			for (events in gmx.findAll("events"))
			for (event in events.findAll("event")) {
				if (event.get("eventtype") == etype
				&& event.get("enumb") == enumb
				&& event.get("ename") == ename) {
					return GmlFile.open(parent, path, { def: edef });
				}
			}
			parent = gmx.findText("parentName");
		}
		return null;
	}
}
