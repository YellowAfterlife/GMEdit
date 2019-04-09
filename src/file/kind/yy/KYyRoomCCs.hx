package file.kind.yy;

import editors.EditCode;
import file.kind.KGml;
import haxe.Json;
import parsers.GmlSeeker;
import tools.NativeArray;
import yy.YyRooms;

/**
 * ...
 * @author YellowAfterlife
 */
class KYyRoomCCs extends KGml {
	public static var inst:KYyRoomCCs = new KYyRoomCCs();
	public function new() {
		super();
	}
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		if (data == null) data = Json.parse(super.loadCode(editor, data));
		var file = editor.file;
		NativeArray.clear(file.extraFiles);
		var code = YyRooms.getCCs(file.path, data, file.extraFiles);
		GmlSeeker.runSync(file.path, code, "", file.kind);
		return code;
	}
	override public function saveCode(editor:EditCode, code:String):Bool {
		if (code == null) return null;
		if (!YyRooms.setCCs(editor.file.path, code, editor.file.extraFiles)) {
			editor.setSaveError("Can't update CCs:\n" + YyRooms.errorText);
			return false;
		}
		return true;
	}
}
