package gmk.gm82;

import ace.extern.AceAutoCompleteItem;
import gml.GmlAPI;
import haxe.io.BytesInput;
import haxe.io.Bytes;
import tools.Aliases.FullPath;
import tools.StringBuilder;

class GedLoader {
	public static function run(bytes:Bytes, ?api:StringBuf) {
		var reader = new BytesInput(bytes);
		inline function int() {
			return reader.readInt32();
		}
		inline function bool() {
			return reader.readInt32() != 0;
		}
		function string() {
			var len = reader.readInt32();
			return reader.readString(len, UTF8);
		}
		var version = int();
		var editable = bool();
		var extName = string();
		var folder = string();
		var version = string();
		var author = string();
		var date = string();
		var license = string();
		var description = string();
		var helpFile = string();
		var hidden = bool();
		//
		var useCount = int();
		for (_ in 0 ... useCount) string();
		//
		var fileCount = int();
		for (_ in 0 ... fileCount) {
			var fileVersion = int();
			var fileName = string();
			var origName = string();
			var fileKind = int();
			var initFunc = string();
			var finalFunc = string();
			//
			var bufPublic = api != null ? new StringBuilder() : null;
			var bufPrivate = api != null ? new StringBuilder() : null;
			inline function getBuffer(hidden:Bool) {
				var buf = hidden ? bufPrivate : bufPublic;
				if (buf != null && buf.length == 0) {
					buf.addFormat("#section %s", fileName);
					if (hidden) buf.add(" (hidden)");
					buf.add("\n");
				}
				return buf;
			}
			if (initFunc != "" || finalFunc != "") {
				var buf = getBuffer(false);
				if (initFunc != "") buf.addFormat("// init: %s\n", initFunc);
				if (finalFunc != "") buf.addFormat("// final: %s\n", finalFunc);
			}
			//
			for (_ in 0 ... int()) {
				var funcVersion = int();
				var funcName = string();
				var funcExtName = string();
				var funcCallConv = int();
				var funcHelp = string();
				var funcHidden = bool();
				var funcArgs = int();
				var funcArgTypes = [];
				for (_ in 0 ... 17) {
					funcArgTypes.push(int());
				}
				var resType = int();
				//
				GmlAPI.extKind.set(funcName, "extfunction");
				GmlAPI.extArgc[funcName] = funcArgs;
				if (!funcHidden && funcHelp != "") {
					GmlAPI.extCompAdd(new AceAutoCompleteItem(
						funcName, "function", funcHelp
					));
					GmlAPI.extDoc.set(funcName, gml.GmlFuncDoc.parse(funcHelp));
				}
				//
				var buf:StringBuilder = getBuffer(funcHidden);
				if (buf != null) {
					if (funcHelp != "") {
						buf.add(funcHelp);
					} else {
						buf.addFormat("%s(", funcName);
						if (funcArgs == 0) {
							buf.addString(")");
						} else if (funcArgs < 0) {
							buf.addString("...)");
						} else {
							buf.addFormat("%s)", funcArgTypes.join(", "));
						}
					}
					buf.add("\n");
				}
			}
			//
			for (_ in 0 ... int()) {
				var constVersion = int();
				var constName = string();
				var constValue = string();
				var constHidden = bool();
				GmlAPI.extKind[constName] = "extmacro";
				if (!constHidden) {
					GmlAPI.extCompAdd(new AceAutoCompleteItem(
						constName, "macro", '($constValue)'
					));
				}
				var buf:StringBuilder = getBuffer(constHidden);
				if (buf != null) {
					buf.addFormat("%s = %s\n", constName, constValue);
				}
			}
			//
			if (api != null) {
				api.add(bufPublic.toString());
				api.add(bufPrivate.toString());
			}
		} // for file
	}
}