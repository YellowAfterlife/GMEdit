package parsers;

import gml.GmlVersion;
import parsers.GmlReader;
import massive.munit.Assert;

class GmlReaderTest {
	
	@Test
	public function parseLocalStringVariable() {
		GmlVersion.init();
		var gmlReader = new GmlReader("var a = \"hello\"", GmlVersion.v2);
		Assert.areEqual("var", gmlReader.readIdent());
		gmlReader.skipNops();
		Assert.areEqual("a", gmlReader.readIdent());
		gmlReader.skipNops();
		Assert.areEqual("=".code, gmlReader.read());
		gmlReader.skipNops();
		gmlReader.skipString1('"'.code);
		gmlReader.skipStringAuto('"'.code, GmlVersion.v2);
		Assert.areEqual(true, gmlReader.eof);
	}
		
}