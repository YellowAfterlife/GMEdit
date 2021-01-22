package file.kind.gml;
import parsers.*;
import editors.EditCode;
import editors.Editor;
import electron.Dialog;
import synext.GmlExtArgs;
import synext.GmlExtArgsDoc;
import synext.GmlExtCoroutines;
import synext.GmlExtHyper;
import synext.GmlExtLambda;
import ui.Preferences;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmlScript extends KGml {
	public static var inst:KGmlScript = new KGmlScript();
	public var isScript:Bool = true;
	public function new() {
		super();
		canDefineComp = true;
	}
	
	//{ Freshly made empty GML files don't exist on disk
	private var doesNotExist:Bool = false;
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		if (data != null) return data;
		if (electron.FileWrap.existsSync(editor.file.path)) {
			var text = electron.FileWrap.readTextFileSync(editor.file.path);
			doesNotExist = false;
			return text;
		} else {
			Main.console.warn('`${editor.file.path}` is amiss, assuming to be empty.');
			doesNotExist = true;
			return "";
		}
	}
	override public function saveCode(editor:EditCode, code:String):Bool {
		doesNotExist = false;
		return super.saveCode(editor, code);
	}
	override public function checkForChanges(editor:Editor):Int {
		var result = super.checkForChanges(editor);
		if (result == -1 && doesNotExist) result = 0;
		return result;
	}
	//}
	
	override public function preproc(editor:EditCode, code:String):String {
		code = GmlExtCoroutines.pre(code);
		code = super.preproc(editor, code);
		code = GmlExtArgs.pre(code);
		return code;
	}
	public function postproc_1(editor:EditCode, out:String, sessionChanged:Bool):String {
		inline function error(s:String) {
			Dialog.showError(s);
			return null;
		}
		var file = editor.file;
		var onDisk = file.path != null;
		//
		out = GmlExtArgs.post(out);
		if (out == null) return error("Can't process #args:\n" + GmlExtArgs.errorText);
		//
		var canCoroutines = isScript;
		if (isScript && Preferences.current.argsFormat != "") {
			if (!sessionChanged && GmlExtArgsDoc.proc(file)) {
				sessionChanged = true;
				out = editor.session.getValue();
				// hm, yeah, I guess we have to do it all again now?
				// think of something better later
				if (onDisk && canImport) {
					var pair = editor.postpImport(out);
					if (pair == null) return null;
					out = pair.val;
				}
				if (canLambda) {
					out = GmlExtLambda.post(editor, out);
					if (out == null) return error("Can't process #lambda:\n" + GmlExtLambda.errorText);
				}
				out = postproc_1(editor, out, true);
				if (out == null) return null;
				canCoroutines = false;
				Main.window.setTimeout(function() {
					file.markClean();
				});
			}
		}
		//
		if (canCoroutines) {
			out = GmlExtCoroutines.post(out);
			if (out == null) return error(GmlExtCoroutines.errorText);
		}
		//
		return out;
	}
	override public function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		if (code == null) return code;
		return postproc_1(editor, code, saveSessionChanged);
	}
}
