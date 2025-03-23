package file.kind.yy;

import editors.EditCode;
import electron.FileWrap;
import file.kind.KCode;
import yy.YyJson;
import yy.YyProject;
using StringTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class KYyRoomOrder extends KCode {
	public static var inst = new KYyRoomOrder();
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		if (data == null) data = YyJson.parse(super.loadCode(editor, data));
		var yyp:YyProject = data;
		var arr = [];
		for (node in yyp.RoomOrderNodes) {
			arr.push(node.roomId.name);
		}
		return arr.join("\n");
	}
	override public function saveCode(editor:EditCode, code:String):Bool {
		var yyp:YyProject = FileWrap.readYyFileSync(editor.file.path, null, true);
		var names = code.replace("\r", "").split("\n");
		names = names.map(s -> s.trimBoth());
		names = names.filter(s -> s != "");
		//
		var roomMap = new Map();
		for (res in yyp.resources) {
			if (res.id.path.startsWith("rooms/")) roomMap[res.id.name] = res.id;
		}
		//
		var nodes = yyp.RoomOrderNodes;
		nodes.resize(0);
		for (name in names) {
			var ref = roomMap[name];
			if (ref != null) {
				nodes.push({ roomId: ref });
			} else {
				editor.setSaveError('Room "$name" does not exist!');
				return false;
			}
		}
		FileWrap.writeYyFileSync(editor.file.path, yyp, true);
		return true;
	}
}