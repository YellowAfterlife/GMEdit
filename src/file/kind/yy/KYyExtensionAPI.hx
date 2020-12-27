package file.kind.yy;
import editors.EditCode;
import gml.GmlExtensionAPI;
import yy.YyJson;

/**
 * ...
 * @author YellowAfterlife
 */
class KYyExtensionAPI extends KGml {
	public static var inst:KYyExtensionAPI = new KYyExtensionAPI();
	public function new() {
		super();
		canLambda = false;
		canImport = false;
		canHyper = false;
		canSyntaxCheck = false;
	}
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		if (data == null) data = YyJson.parse(super.loadCode(editor, data));
		return GmlExtensionAPI.get2(data);
	}
	override public function saveCode(editor:EditCode, code:String):Bool {
		return false;
	}
}
