package file.kind.gmx;
import editors.EditCode;
import electron.FileWrap;
import gmx.GmxTimeline;
import gmx.SfGmx;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmxMoments extends KGml {
	public static var inst:KGmxMoments = new KGmxMoments();
	public function new() {
		super();
	}
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		var root = SfGmx.parse(super.loadCode(editor, data));
		var code = GmxTimeline.getCode(root);
		if (code != null) return code;
		return editor.setLoadError(GmxTimeline.errorText);
	}
	override public function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		if (code == null) return null;
		var root = FileWrap.readGmxFileSync(editor.file.path);
		if (!GmxTimeline.setCode(root, code)) {
			editor.setSaveError("Can't update GMX:\n" + GmxTimeline.errorText);
			return null;
		}
		return root.toGmxString();
	}
}
