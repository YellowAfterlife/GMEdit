package file.kind;
import editors.EditCode;
import electron.Dialog;
import parsers.GmlExtHyper;
import parsers.GmlExtImport;
import parsers.GmlExtLambda;

/**
 * A parent for any kinds containing GML code.
 * @author YellowAfterlife
 */
class KGml extends KCode {
	
	/// Whether #import magic is supported for this kind
	public var canImport:Bool = true;
	
	/// Whether #lambda magic is supported for this kind
	public var canLambda:Bool = true;
	
	/// Whether #hyper magic is supported for this kind
	public var canHyper:Bool = true;
	
	/**
	 * Whether editor session had been modified during the current save operation.
	 * We need this because trying to modify it multiple times can be destructive.
	 */
	public var saveSessionChanged:Bool;
	
	public function new() {
		super();
		modePath = "ace/mode/gml";
	}
	
	override public function preproc(editor:EditCode, code:String):String {
		var onDisk = editor.file.path != null;
		if (onDisk && canLambda) code = GmlExtLambda.pre(editor, code);
		if (onDisk && canImport) code = GmlExtImport.pre(code, editor.file.path);
		if (canHyper) code = GmlExtHyper.pre(code);
		return code;
	}
	
	override public function postproc(editor:EditCode, code:String):String {
		saveSessionChanged = false;
		var onDisk = editor.file.path != null;
		if (canHyper) code = GmlExtHyper.post(code);
		if (onDisk && canImport) {
			var pair = editor.postpImport(code);
			if (pair == null) return null;
			code = pair.val;
			if (pair.sessionChanged) saveSessionChanged = true;
		}
		if (onDisk && canLambda) {
			code = GmlExtLambda.post(editor, code);
			if (code == null) {
				Dialog.showError("Can't process #lambda:\n" + GmlExtLambda.errorText);
				return null;
			}
		}
		return code;
	}
}
