package file.kind.gmk;

import parsers.GmlSeekData;
import parsers.GmlSeeker;
import electron.FileWrap;
import gmk.gm82.Gm82Object;
import editors.EditCode;

class KGm82Events extends file.kind.gml.KGmlEvents {
	public static var inst:KGm82Events = new KGm82Events();
	
	override function loadCode(editor:EditCode, data:Dynamic):String {
		var path = editor.file.path;
		if (data == null) data = FileWrap.readTextFileSync(path);
		var out = Gm82Object.getCode(data);
		if (out == null) {
			return editor.setLoadError(Gm82Object.errorText);
		} else return out;
	}
	override function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		if (code == null) return null;
		code = Gm82Object.setCode(code);
		if (code == null) {
			editor.setSaveError(Gm82Object.errorText);
			return null;
		} else return code;
	}
	override function index(path:String, content:String, main:String, sync:Bool):Bool {
		var out = new GmlSeekData(this);
		GmlSeeker.finish(path, out);
		return true;
	}
}