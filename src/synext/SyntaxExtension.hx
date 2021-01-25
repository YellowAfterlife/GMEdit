package synext;
import editors.EditCode;
import electron.Dialog;
import tools.JsTools;

/**
 * ...
 * @author YellowAfterlife
 */
class SyntaxExtension {
	public var name:String;
	public var displayName:String;
	/** If returning null from preproc/postproc, this should indicate why you did so */
	public var message:String;
	
	public function new(name:String, displayName:String) {
		this.name = name;
		this.displayName = displayName;
	}
	
	/** Can return whether this extension should apply */
	public function check(editor:EditCode, code:String):Bool {
		return true;
	}
	
	/** Pre-processor */
	public function preproc(editor:EditCode, code:String):String {
		return code;
	}
	
	/** Post-processor */
	public function postproc(editor:EditCode, code:String):String {
		return code;
	}
	
	/**
	 * Goes over each synext in array and applies it to code in order.
	 * Bails if any return null or error out.
	 */
	public static function preprocArray(editor:EditCode, code:String, sxs:Array<SyntaxExtension>):String {
		for (sx in sxs) {
			inline function proc():Bool {
				if (sx.check(editor, code)) {
					code = sx.preproc(editor, code);
					if (code == null) {
						var e = JsTools.or(sx.message, "(unspecified error)");
						Dialog.showError('An error occurred in ${sx.displayName} preprocessor:\n' + e);
						return true;
					} else return false;
				} else return false;
			}
			#if test
			if (proc()) return null;
			#else
			try {
				if (proc()) return null;
			} catch (x:Dynamic) {
				Dialog.showError('An error occurred in ${sx.displayName} preprocessor:\n' + Std.string(x));
			}
			#end
		}
		return code;
	}
	
	/**
	 * NB! Goes in reverse so that the same array can be reused for pre/post
	 */
	public static function postprocArray(editor:EditCode, code:String, sxs:Array<SyntaxExtension>):String {
		var i = sxs.length;
		while (--i >= 0) {
			var sx = sxs[i];
			inline function proc():Bool {
				if (sx.check(editor, code)) {
					code = sx.postproc(editor, code);
					if (code == null) {
						var e = JsTools.or(sx.message, "(unspecified error)");
						var text = 'An error occurred in ${sx.displayName} postprocessor:\n' + e;
						#if test
						throw text;
						#else
						trace("not test??");
						Dialog.showError(text);
						#end
						return true;
					} else return false;
				} else return false;
			}
			#if test
			if (proc()) return null;
			#else
			try {
				if (proc()) return null;
			} catch (x:Dynamic) {
				Dialog.showError('An error occurred in ${sx.displayName} postprocessor:\n' + Std.string(x));
			}
			#end
		}
		return code;
	}
}