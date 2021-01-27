package test_helpers;

import file.kind.KGml;
import tools.Aliases.GmlCode;
import gml.file.GmlFileInMemory;

class GmlFileHelper {
	private static var testCounter : Int = 0;

	public static function makeGmlFile(code : GmlCode) {
		var name = "test" + testCounter++;
		return new GmlFileInMemory(name, KGml.inst, code);
	}

}