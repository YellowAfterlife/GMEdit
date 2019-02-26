package file.kind.gmx;
import editors.EditCode;
import gml.GmlExtensionAPI;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmxExtensionAPI extends KGml {
	public static var inst:KGmxExtensionAPI = new KGmxExtensionAPI();
	public function new() {
		super();
		canLambda = false;
		canImport = false;
		canHyper = false;
	}
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		if (data == null) data = super.loadCode(editor, data);
		return GmlExtensionAPI.get1(data);
	}
	override public function saveCode(editor:EditCode, code:String):Bool {
		return false;
	}
}
