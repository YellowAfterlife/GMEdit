package file.kind.yy;

import editors.EditCode;
import file.kind.KGml;
import haxe.Json;
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
		return YyRooms.getCCs(file.path, data, file.extraFiles);
	}
	override public function saveCode(editor:EditCode, code:String):Bool {
		code = super.postproc(editor, code);
		if (code == null) return null;
		if (!YyRooms.setCCs(editor.file.path, code, editor.file.extraFiles)) {
			editor.setSaveError("Can't update CCs:\n" + YyRooms.errorText);
			return false;
		}
		return true;
	}
}
