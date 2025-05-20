package file.kind.gmk;

import editors.EditCode;
import file.kind.misc.KPlain;
import gml.Project;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmkSnips extends KPlain {
	public static var inst = new KGmkSnips();
	
	override public function saveCode(editor:EditCode, code:String):Bool {
		var result = super.saveCode(editor, code);
		if (editor.file.path == Project.current.path) {
			Main.window.setTimeout(function() {
				Project.current.reload();
			});
		}
		return result;
	}
}