package gmk.gm82;

import gml.GmlVersion;
import parsers.GmlEvent;
import electron.Dialog;
import parsers.GmlMultifile;

class Gm82Object {
	public static var errorText:String;
	public static function getCode(objectGml:String) {
		var sections = GmlMultifile.split(objectGml, "");
		if (sections == null) {
			errorText = GmlMultifile.errorText;
			return null;
		}
		var out = new StringBuf();
		var sep = false;
		for (i => sct in sections) {
			var type_numb = sct.name;
			var splitAt = type_numb.indexOf("_");
			var type = type_numb.substring(0, splitAt);
			var arg = type_numb.substring(splitAt + 1);
			var typeInd = GmlEvent.getCapTypeIndex(type);
			var argInd:Null<Int> = null;
			if (typeInd != GmlEvent.typeCollision) {
				argInd = Std.parseInt(arg);
			}
			var eventName = GmlEvent.toString(typeInd, argInd, arg);
			//
			if (sep) {
				out.add("\n");
			} else sep = true;
			out.add("#event " + eventName + "\n");
			out.add(Gm82Action.preproc(sct.code));
		}
		return out.toString();
	}
	public static function setCode(gmlCode:String) {
		var eventData = GmlEvent.parse(gmlCode, GmlVersion.v1);
		if (eventData == null) {
			errorText = GmlEvent.parseError;
			return null;
		}
		var out = new StringBuf();
		var sep = false;
		for (event in eventData) {
			var data = event.data;
			var name = GmlEvent.getTypeNameCap(data.type) + "_";
			if (data.type == GmlEvent.typeCollision) {
				name += data.name;
			} else name += data.numb;
			//
			/*if (sep) {
				out.add("\n");
			} else sep = true;*/
			//
			out.add("#define " + name + "\n");
			var snip = Gm82Action.postproc(event.code);
			if (snip == null) {
				errorText = Gm82Action.errorText;
				return null;
			}
			out.add(snip);
			out.add("\n");
		}
		return out.toString();
	}
}