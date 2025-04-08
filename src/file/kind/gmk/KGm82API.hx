package file.kind.gmk;

import editors.EditCode;
import file.kind.KCode;
import file.kind.KGml;

/**
 * ...
 * @author YellowAfterlife
 */
class KGm82API extends KGml {
	public static var inst = new KGm82API();
	public function new() {
		super();
		canLambda = false;
		canImport = false;
		canHyper = false;
		canSyntaxCheck = false;
	}
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		return data;
	}
	override public function saveCode(editor:EditCode, code:String):Bool {
		return false;
	}
}