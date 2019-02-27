package file.kind.misc;
import ace.AceSnippets;
import editors.EditCode;
import editors.Editor;

/**
 * ...
 * @author YellowAfterlife
 */
class KSnippets extends KCode {
	public static var inst:KSnippets = new KSnippets();
	public function new() {
		super();
		
	}
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		return AceSnippets.getText(editor.file.path);
	}
	override public function saveCode(editor:EditCode, code:String):Bool {
		AceSnippets.setText(editor.file.path, code);
		return true;
	}
	override public function checkForChanges(editor:Editor):Int {
		return 0;
	}
}
