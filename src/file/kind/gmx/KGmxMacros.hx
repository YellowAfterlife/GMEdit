package file.kind.gmx;
#if !gmedit.no_gmx
import editors.EditCode;
import electron.FileWrap;
import gmx.GmxProject;
import gmx.SfGmx;
import parsers.GmlReader;
import tools.StringBuilder;

/**
 * Assembles GMS1 macros and an annotation file into a single-tab editor.
 * @author YellowAfterlife
 */
class KGmxMacros extends KGml {
	public var isConfig:Bool;
	public function new(isConfig:Bool) {
		super();
		this.isConfig = isConfig;
	}
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		var root = SfGmx.parse(super.loadCode(editor, data));
		var notePath = editor.file.notePath;
		var noteReader:GmlReader = null;
		if (FileWrap.existsSync(notePath)) {
			noteReader = new GmlReader(FileWrap.readTextFileSync(notePath));
		}
		return GmxProject.getMacroCode(root, noteReader, isConfig);
	}
	override public function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		if (code == null) return null;
		var root = FileWrap.readGmxFileSync(editor.file.path);
		var notes = new StringBuilder();
		GmxProject.setMacroCode(root, code, notes, isConfig);
		var notePath = editor.file.notePath;
		if (notes.length > 0) {
			FileWrap.writeTextFileSync(notePath, notes.toString());
		} else if (FileWrap.existsSync(notePath)) {
			FileWrap.unlinkSync(notePath);
		}
		return root.toGmxString();
	}
}
#end
