package file.kind.yy;
import editors.EditCode;
import electron.FileWrap;
import file.kind.KGml;
import haxe.Json;
import tools.NativeArray;
import tools.NativeString;
import yy.YyObject;
import yy.YyJson;

/**
 * ...
 * @author YellowAfterlife
 */
class KYyEvents extends KGml {
	public static var inst:KYyEvents = new KYyEvents();
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		if (data == null) data = Json.parse(super.loadCode(editor, data));
		var obj:YyObject = data;
		var file = editor.file;
		NativeArray.clear(file.extraFiles);
		return obj.getCode(file.path, file.extraFiles);
	}
	static var eventOrder = YyJson.mvcOrder.concat(["IsDnD"]);
	override public function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		if (code == null) return null;
		var obj:YyObject = FileWrap.readJsonFileSync(editor.file.path);
		if (!obj.setCode(editor.file.path, code)) {
			editor.setSaveError("Can't update YY:\n" + YyObject.errorText);
			return null;
		}
		//
		obj.hxOrder = YyJson.mvcOrder;
		for (event in obj.eventList) event.hxOrder = eventOrder;
		return NativeString.yyJson(obj);
	}
}
