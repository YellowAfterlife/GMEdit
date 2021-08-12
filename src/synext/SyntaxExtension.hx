package synext;
import editors.EditCode;
import electron.Dialog;
import tools.Aliases;
import tools.JsTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class SyntaxExtension {
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
	 * If linter doesn't support your syntax extension, you may modify the code for it here.
	 * NB! Please maintain the line count.
	 */
	public function postprocForLinter(editor:EditCode, code:String):String {
		return code;
	}
	
	@:keep static inline function handleArray(editor:EditCode, code:GmlCode, sxs:Array<SyntaxExtension>,
		func:SyntaxExtension->EditCode->GmlCode->GmlCode, forward:Bool
	):GmlCode {
		var index = forward ? 0 : sxs.length - 1;
		var loop:Bool;
		while (forward ? index < sxs.length : index >= 0) {
			var sx = sxs[forward ? index++ : index--];
			inline function proc():Bool {
				if (sx.check(editor, code)) {
					code = func(sx, editor, code);
					if (code == null) {
						var e = JsTools.or(sx.message, "(unspecified error)");
						Dialog.showError('An error occurred in ${sx.displayName} preprocessor:\n' + e);
						return true;
					} else return false;
				} else return false;
			}
			#if test
			if (proc()) break;
			#else
			try {
				if (proc()) break;
			} catch (x:Dynamic) {
				Dialog.showError('An error occurred in ${sx.displayName} preprocessor:\n' + Std.string(x));
				break;
			}
			#end
		}
		return code;
	}
	
	/**
	 * Goes over each synext in array and applies it to code in order.
	 * Bails if any return null or error out.
	 */
	public static function preprocArray(editor:EditCode, code:String, sxs:Array<SyntaxExtension>):String {
		return handleArray(editor, code, sxs, function(sx, _, code) {
			return sx.preproc(editor, code);
		}, true);
	}
	
	/**
	 * NB! Goes in reverse so that the same array can be reused for pre/post
	 */
	public static function postprocArray(editor:EditCode, code:String, sxs:Array<SyntaxExtension>):String {
		return handleArray(editor, code, sxs, function(sx, _, code) {
			return sx.postproc(editor, code);
		}, false);
	}
	
	/**
	 * NB! Goes in reverse so that the same array can be reused for pre/post
	 */
	public static function postprocForLinterArray(editor:EditCode, code:String, sxs:Array<SyntaxExtension>):String {
		return handleArray(editor, code, sxs, function(sx, _, code) {
			return sx.postprocForLinter(editor, code);
		}, false);
	}
}