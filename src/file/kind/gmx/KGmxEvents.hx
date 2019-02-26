package file.kind.gmx;
import editors.EditCode;
import electron.FileWrap;
import gmx.GmxObject;
import gmx.SfGmx;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmxEvents extends KGml {
	public static var inst:KGmxEvents = new KGmxEvents();
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		var root = SfGmx.parse(super.loadCode(editor, data));
		var out = GmxObject.getCode(root);
		if (out == null) {
			return editor.setLoadError(GmxObject.errorText);
		} else return out;
	}
	override public function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		if (code == null) return null;
		var root = FileWrap.readGmxFileSync(editor.file.path);
		if (!GmxObject.setCode(root, code)) {
			editor.setSaveError("Can't update GMX:\n" + GmxObject.errorText);
			return null;
		}
		return root.toGmxString();
	}
}
