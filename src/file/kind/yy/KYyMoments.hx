package file.kind.yy;

import editors.EditCode;
import electron.FileWrap;
import file.kind.KGml;
import tools.NativeArray;
import tools.NativeString;
import yy.YyTimeline;

/**
 * ...
 * @author YellowAfterlife
 */
class KYyMoments extends KGml {
	public static var inst:KYyMoments = new KYyMoments();
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		if (data == null) data = yy.YyJson.parse(super.loadCode(editor, data));
		var tl:YyTimeline = data;
		var file = editor.file;
		NativeArray.clear(file.extraFiles);
		return tl.getCode(file.path, file.extraFiles);
	}
	override public function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		if (code == null) return null;
		var tl:YyTimeline = FileWrap.readYyFileSync(editor.file.path);
		if (!tl.setCode(editor.file.path, code)) {
			editor.setSaveError("Can't update YY:\n" + YyTimeline.errorText);
			return null;
		}
		return yy.YyJson.stringify(tl, gml.Project.current.yyExtJson);
	}
}
