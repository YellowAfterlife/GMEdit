package file.kind.misc;

import file.kind.KCode;
import gml.file.GmlFile;
import shaders.ShaderHighlight;
import shaders.ShaderKind;

/**
 * ...
 * @author YellowAfterlife
 */
class KGLSL extends KCode {
	public static var inst:KGLSL = new KGLSL();
	public function new() {
		super();
		modePath = "ace/mode/shader";
	}
	override public function init(file:GmlFile, data:Dynamic):Void {
		ShaderHighlight.nextKind = ShaderKind.GLSL;
		super.init(file, data);
	}
}
