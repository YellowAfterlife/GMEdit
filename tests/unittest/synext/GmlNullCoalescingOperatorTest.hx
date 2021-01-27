package synext;

import test_helpers.GmlFileHelper;
import massive.munit.Assert;
import gml.Project;
import file.kind.KGml;
import gml.file.GmlFileInMemory;

class GmlNullCoalescingOperatorTest {

	@Before public function setup() {
		Project.current.properties.nullConditionalSet = "nc_set";
		Project.current.properties.nullConditionalVal = "nc_val";
	}

	@Test public function testPost() {
		var synext = new GmlNullCoalescingOperator();
		function comparePost(input : String, expectedOutput : String) {
			var file = GmlFileHelper.makeGmlFile(input);
			var result = synext.postproc(file.codeEditor, file.readContent());
			Assert.areEqual(expectedOutput, result);
		}
		
		comparePost(
			"var a = b ?? c",
			"var a = nc_set(b) ? nc_val : c"
		);
		comparePost(
			"var a/*comment*/ = b ?? c",
			"var a/*comment*/ = nc_set(b) ? nc_val : c"
		);
		comparePost(
			"var a = b ?? c;",
			"var a = nc_set(b) ? nc_val : c;"
		);
	}

	@Test public function testPre() {
		var synext = new GmlNullCoalescingOperator();
		function comparePre(input : String, expectedOutput : String) {
			var file = GmlFileHelper.makeGmlFile(input);
			var result = synext.preproc(file.codeEditor, file.readContent());
			Assert.areEqual(expectedOutput, result);
		}

		comparePre(
			"var a = nc_set(b) ? nc_val : c",
			"var a = b ?? c"
		);
		comparePre(
			"var c /*comment*/ = nc_set(x) ? nc_val : y",
			"var c /*comment*/ = x ?? y"
		);
	}

	@Test public function testBinaryCorrectness() {
		var synext = new GmlNullCoalescingOperator();
		var codeStrings = [
			"var a = nc_set(x) ? nc_val : y",
			"var b=nc_set(x)?nc_val:y",
			"var c /*comment*/ = nc_set(x) ? nc_val : y",
			"var d /*comment*/ = nc_set(x) /*comment*/ ? /*comment*/ nc_val : /*comment*/ y",
			"var e = \r\n\tnc_set(x) ?\r\n\t\tnc_val:y",
			"var veryLongIdentifierThatsProbablyFineButYouCanNeverKnow = nc_set(anotherIncrediblyLongIdentifier) ? nc_val : y",
			"var f = nc_set(func(150 + 1)) ? nc_val : y",
			"var g = nc_set(func(150 /*comment*/ + 150)) ? nc_val : y",
		];

		for (code in codeStrings) {
			var file = GmlFileHelper.makeGmlFile(code);
			var result = synext.preproc(file.codeEditor, file.readContent());
			var resultBack = synext.postproc(file.codeEditor, result);
			Assert.areEqual(code, resultBack);
		}

	}
}