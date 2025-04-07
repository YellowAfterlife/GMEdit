package gmx;
import gml.*;
import electron.FileWrap;
import gml.file.GmlFile;
import gmx.GmxEvent;
import gmx.GmxObjectProperties;
import gmx.SfGmx;
import haxe.io.Path;
import parsers.GmlEvent;
import tools.NativeArray;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxObject {
	public static var errorText:String;
	public static function getCode(gmx:SfGmx):String {
		var out = GmxObjectProperties.get(gmx);
		var errors = "";
		var objectIDs = GmlAPI.gmlAssetIDs["object"];
		for (evOuter in gmx.findAll("events")) {
			var events = evOuter.findAll("event");
			//
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
			//
			for (event in events) {
				if (out != "") out += "\n\n";
				var name = GmxEvent.toStringGmx(event);
				out += "#event " + name;
				// to say, GMS will usually purge empty events on save, but just in case:
				if (GmxEvent.isEmpty(event)) continue;
				var code = GmxEvent.getCode(event);
				if (code != null) {
					var pair = parsers.GmlHeader.parse(code, GmlVersion.v1);
					if (pair.name != null) out += pair.name;
					out += "\n" + pair.code;
				} else {
					errors += "Unreadable action in " + name + ":\n";
					errors += GmxAction.errorText + "\n";
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
		var filterErrors = "";
		NativeArray.filterSelf(eventData, function(item) {
			var idat:GmlEventData = item.data;
			if (idat.type != GmlEvent.typeMagic) return true;
			if (idat.numb != GmlEvent.kindMagicProperties) return true;
			var err = GmxObjectProperties.set(gmx, item.code.join("\n"));
			if (err != null) filterErrors += err;
			return false;
		});
		if (filterErrors != "") {
			errorText = filterErrors;
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
			if (source.code.length > 0) {
				for (gml in source.code) {
					var a = GmxAction.makeCodeBlock(gml);
					if (a == null) {
						errorText = GmxAction.errorText;
						return false;
					} else event.addChild(a);
				}
			} else event.addChild(GmxAction.makeCodeBlock(""));
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
		var gmx = FileWrap.readGmxFileSync(full);
		var parent = gmx.findText("parentName");
		var tries = 1024;
		while (parent != "<undefined>" && --tries >= 0) {
			var path = Path.join([dir, parent + ".object.gmx"]);
			if (!FileWrap.existsSync(path)) return null;
			gmx = FileWrap.readGmxFileSync(path);
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
	public static function getInfo(gmx:SfGmx, path:String, ?info:GmlObjectInfo):GmlObjectInfo {
		var objName = Path.withoutExtension(Path.withoutExtension(Path.withoutDirectory(path)));
		if (info == null) {
			info = new GmlObjectInfo();
			info.spriteName = gmx.findText("spriteName");
			info.objectName = objName;
			info.visible = gmx.findText("visible") != "0";
			info.persistent = gmx.findText("persistent") != "0";
			info.solid = gmx.findText("solid") != "0";
			info.depth = Std.parseFloat(gmx.findText("depth"));
		}
		//
		for (events in gmx.findAll("events"))
		for (event in events.findAll("event")) {
			var enumb = event.get("enumb");
			var eid = GmlEvent.toString(
				Std.parseInt(event.get("eventtype")),
				enumb != null ? Std.parseInt(enumb) : null,
				event.get("ename")
			);
			var elist = info.eventMap[eid];
			if (elist == null) {
				elist = [];
				info.eventList.push(eid);
				info.eventMap.set(eid, elist);
			}
			elist.unshift(objName + "(" + eid + ")");
		}
		//
		var parent = gmx.findText("parentName");
		if (parent != "" && parent != "<undefined>") {
			var parentPath = Path.join([Path.directory(path), parent + ".object.gmx"]);
			info.parents.unshift(parent);
			if (FileWrap.existsSync(parentPath)) {
				var parentGmx = FileWrap.readGmxFileSync(parentPath);
				getInfo(parentGmx, parentPath, info);
			}
		}
		return info;
	}
}
