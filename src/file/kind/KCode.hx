package file.kind;

import editors.EditCode;
import electron.Dialog;
import electron.FileWrap;
import file.FileKind;
import gml.file.GmlFile;
import electron.FileSystem;

/**
 * ...
 * @author YellowAfterlife
 */
class KCode extends FileKind {
	
	/// language mode path for Ace
	public var modePath:String = "ace/mode/text";
	
	/// whether to do a GmlSeeker pass after saving to update definitions
	public var indexOnSave:Bool = false;
	
	/**
	 * Whether to set GmlFile.changed when code gets changed
	 * @see AceStatusBar.update
	 */
	public var setChangedOnEdits:Bool = true;
	
	public function new() {
		super();
	}
	
	override public function init(file:GmlFile, data:Dynamic):Void {
		file.codeEditor = new EditCode(file, modePath);
		file.editor = file.codeEditor;
	}
	
	public function loadCode(editor:EditCode, data:Dynamic):String {
		return data != null ? data : editor.file.readContent();
	}
	public function saveCode(editor:EditCode, code:String):Bool {
		if (editor.file.path == null) return false;
		return editor.file.writeContent(code);
	}
	
	/**
	 * Executed after getting the code from loadCode for pre-processing
	 * @return Modified code
	 */
	public function preproc(editor:EditCode, code:String):String {
		return code;
	}
	
	/**
	 * Executed before passing the code to saveCode for post-processing
	 * Whatever returned from here is then passed to saveCode.
	 * @return New code or null on error
	 */
	public function postproc(editor:EditCode, code:String):String {
		return code;
	}
}
