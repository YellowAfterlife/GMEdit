package file.kind.gmx;

import editors.EditCode;
import file.kind.KGml;
import gmx.SfGmx;
import haxe.Json;
import parsers.GmlSeeker;
import tools.NativeArray;
import gmx.GmxRooms;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmxRoomCCs extends KGml {
	public static var inst:KGmxRoomCCs = new KGmxRoomCCs();
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		if (data == null) data = super.loadCode(editor, data);
		if (data is String) data = SfGmx.parse(data);
		//
		var file = editor.file;
		NativeArray.clear(file.extraFiles);
		var code = GmxRooms.getCCs(file.path, data, file.extraFiles);
		GmlSeeker.runSync(file.path, code, "", file.kind);
		return code;
	}
	override public function saveCode(editor:EditCode, code:String):Bool {
		if (code == null) return null;
		if (!GmxRooms.setCCs(editor.file.path, code, editor.file.extraFiles)) {
			editor.setSaveError("Can't update CCs:\n" + GmxRooms.errorText);
			return false;
		}
		return true;
	}
}