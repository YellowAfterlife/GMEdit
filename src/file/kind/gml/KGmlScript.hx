package file.kind.gml;
import parsers.*;
import editors.EditCode;
import electron.Dialog;
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
		out = GmlExtHyper.post(out);
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
		return postproc_1(editor, code, saveSessionChanged);
	}
}
