package yy;
import ace.AceMacro;
import electron.FileSystem;
import electron.FileWrap;
import gml.Project;
import gml.file.GmlFileExtra;
import haxe.Json;
import js.lib.RegExp;
import parsers.GmlReader;
import tools.Dictionary;
import tools.NativeString;
using tools.NativeString;
using tools.PathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class YyRooms {
	public static var errorText:String;
	public static function getCCs(pjPath:String, pjd:YyProject, extraFiles:Array<GmlFileExtra>):String {
		var pjDir:String = pjPath.ptDir();
		var out:String = "";
		var pj = Project.current;
		var v23 = pj.isGMS23;
		if (v23) for (pair in pjd.resources) {
			if (!pair.id.path.startsWith("rooms/")) continue;
			try {
				var rccPath = pair.id.path.ptDir() + "/RoomCreationCode.gml";
				if (!pj.existsSync(rccPath)) continue;
				var rcc = pj.readTextFileSync(rccPath);
				if (rcc.trimBoth() == "") continue;
				if (out != "") out += "\n\n";
				out += "#target " + pair.id.name + "\n" + rcc;
				extraFiles.push(new GmlFileExtra(pj.fullPath(rccPath)));
			} catch (x:Dynamic) {
				Main.console.error('Error reading RCC from room ${pair.id.name}: ', x);
			}
		}
		else for (pair in pjd.resources) {
			var res = pair.Value;
			if (res.resourceType != "GMRoom") continue;
			try {
				var roomFull:String = pjDir.ptJoin(res.resourcePath);
				var room:YyRoom = FileWrap.readYyFileSync(roomFull);
				var roomCCrel = room.creationCodeFile;
				if (roomCCrel == "") continue;
				var roomCCfull = roomFull.ptDir().ptJoin(roomCCrel);
				var roomName = roomFull.ptNoDir().ptNoExt();
				if (out != "") out += "\n\n";
				out += "#target " + roomName
					+ "\n" + FileWrap.readTextFileSync(roomCCfull);
				extraFiles.push(new GmlFileExtra(roomCCfull));
			} catch (_:Dynamic) {
				//
			}
		}
		return out;
	}
	private static function parse(code:String):YyRoomParse {
		var map = new Dictionary<String>();
		var pairs:Array<YyRoomPair> = [];
		var q = new GmlReader(code, gml.GmlVersion.v2);
		var start = 0;
		var name:String = null;
		var code:String = null;
		function flush(p:Int):Bool {
			code = q.substring(start, p).trimRight();
			if (name == null) {
				if (code != "") {
					errorText = "There's code prior to first room creation code!\n" + code;
					return true;
				}
			} else {
				if (map.exists(name)) {
					errorText = 'Room creation code for $name is defined twice!';
					return true;
				}
				map.set(name, code);
				pairs.push({name:name, code:code});
			}
			return false;
		}
		//
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, gml.GmlVersion.v2);
				case "#".code if ((p == 0 || q.get(p - 1) == "\n".code)
					&& q.substr(p + 1, 6) == "target"
					&& q.get(p + 7).isSpace0()
				): {
					q.pos += 6;
					q.skipSpaces0();
					var nameStart = q.pos;
					q.skipIdent1();
					if (q.pos == nameStart) continue;
					if (flush(p)) return null;
					name = q.substring(nameStart, q.pos);
					q.skipSpaces0();
					q.skipLineEnd();
					start = q.pos;
				};
			}
		}
		if (flush(q.pos)) return null;
		return {map:map,pairs:pairs};
	}
	public static function setCCs(pjPath:String, code:String, extraFiles:Array<GmlFileExtra>):Bool {
		// todo: use GmlMultifile.split(code, "", "target")
		var data = parse(code);
		if (data == null) return false;
		
		var pj = Project.current;
		var v23 = pj.isGMS23;
		var pjDir:String = pjPath.ptDir();
		var pjd:YyProject = FileWrap.readYyFileSync(pjPath);
		
		// remove:
		var xi = extraFiles.length;
		var xmap = new Dictionary();
		while (--xi >= 0) {
			var xf:GmlFileExtra = extraFiles[xi];
			var xrel = xf.path.ptNoDir();
			var dir = xf.path.ptDir();
			var name = dir.ptNoDir();
			xmap.set(name, true);
			if (data.map.exists(name)) continue;
			try {
				if (!v23) {
					var rmFull = dir.ptJoin(name + ".yy");
					var rmTxt = FileWrap.readTextFileSync(rmFull);
					rmTxt = NativeString.replaceExt(rmTxt,
						new RegExp('("creationCodeFile":\\s*")' + xrel.escapeRx() + '"', 'g'),
						'$1"');
					FileWrap.writeTextFileSync(rmFull, rmTxt);
				}
				FileWrap.unlinkSync(xf.path);
			} catch (x:Dynamic) {
				Main.console.error("Error removing creation code for " + name + ":", x);
			}
			extraFiles.splice(xi, 1);
		}
		for (pair in data.pairs) {
			var name = pair.name;
			var code = pair.code;
			var full = pjDir.ptJoin("rooms", name, "RoomCreationCode.gml");
			if (!xmap.exists(name)) {
				var rmFull = pjDir.ptJoin("rooms", name, name + ".yy");
				if (!FileWrap.existsSync(rmFull)) {
					errorText = 'Room $name doesn\'t exist!';
					return false;
				}
				if (!v23) try {
					var rmTxt = FileWrap.readTextFileSync(rmFull);
					rmTxt = rmTxt.replaceExt(
						AceMacro.jsRx(~/("creationCodeFile":\\s*")[^"]*"/g),
						"$1RoomCreationCode.gml");
					FileWrap.writeTextFileSync(rmFull, rmTxt);
				} catch (x:Dynamic) {
					errorText = 'Error adding creation code for $name:\n' + x;
					return false;
				}
				extraFiles.push(new GmlFileExtra(full));
			}
			try {
				FileWrap.writeTextFileSync(full, code);
			} catch (x:Dynamic) {
				errorText = 'Error saving code for $name:\n' + x;
				return false;
			}
		}
		return true;
	}
}
private typedef YyRoomParse = {
	pairs:Array<YyRoomPair>,
	map:Dictionary<String>,
};
private typedef YyRoomPair = {
	name:String, code:String,
};
