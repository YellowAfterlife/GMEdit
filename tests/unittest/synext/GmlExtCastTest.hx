package synext;

import test_helpers.GmlFileHelper;
import massive.munit.Assert;
import gml.Project;
import file.kind.KGml;
import gml.file.GmlFileInMemory;

class GmlExtCastTest {
	@Test public function testAsPost() {
		var synext = new GmlExtCast();
		function comparePost(input : String, expectedOutput : String) {
			var file = GmlFileHelper.makeGmlFile(input);
			var result = synext.postproc(file.codeEditor, file.readContent());
			Assert.areEqual(expectedOutput, result);
		}
		
		comparePost(
			"var a = b as number",
			"var a = b /*#as number*/"
		);
		comparePost(
			"func(a, b as number);",
			"func(a, b /*#as number*/);"
		);
		comparePost(
			"func(a, b as number + 5)",
			"func(a, b /*#as number*/ + 5)"
		);
		comparePost(
			"var a = b as any as number",
			"var a = b /*#as any*/ /*#as number*/"
		);
	}

	@Test public function testAsPre() {
		var synext = new GmlExtCast();
		function comparePre(input : String, expectedOutput : String) {
			var file = GmlFileHelper.makeGmlFile(input);
			var result = synext.preproc(file.codeEditor, file.readContent());
			Assert.areEqual(expectedOutput, result);
		}

		comparePre(
			"var a = b /*#as number*/",
			"var a = b as number"
		);
		comparePre( // nothing happens
			"var a = b /*like as number*/",
			"var a = b /*like as number*/"
		);
		comparePre( // nothing happens
			"var a = b /*as number*/",
			"var a = b /*as number*/"
		);
		comparePre( // nothing happens
			"var a = b /*#123456 is my favorite color*/",
			"var a = b /*#123456 is my favorite color*/"
		);
	}

	@Test public function testAsBinaryCorrectness() {
		var synext = new GmlExtCast();
		var codeStrings = [
			"var a = x /*#as number*/",
			"func(b, x /*#as number*/);",
			"var c = x /*#as any*/ /*as number*/"
		];

		for (code in codeStrings) {
			var file = GmlFileHelper.makeGmlFile(code);
			var result = synext.preproc(file.codeEditor, file.readContent());
			var resultBack = synext.postproc(file.codeEditor, result);
			Assert.areEqual(code, resultBack);
		}

	}


	@Test public function testCastPost() {
		var synext = new GmlExtCast();
		function comparePost(input : String, expectedOutput : String) {
			var file = GmlFileHelper.makeGmlFile(input);
			var result = synext.postproc(file.codeEditor, file.readContent());
			Assert.areEqual(expectedOutput, result);
		}
		
		comparePost(
			"var a = cast b",
			"var a = /*#cast*/ b"
		);
	}



	@Test public function testCastPre() {
		var synext = new GmlExtCast();
		function comparePre(input : String, expectedOutput : String) {
			var file = GmlFileHelper.makeGmlFile(input);
			var result = synext.preproc(file.codeEditor, file.readContent());
			Assert.areEqual(expectedOutput, result);
		}

		comparePre(
			"var a = /*#cast*/ b",
			"var a = cast b"
		);
	}

	@Test public function testCastBinaryCorrectness() {
		var synext = new GmlExtCast();
		var codeStrings = [
		];

		for (code in codeStrings) {
			var file = GmlFileHelper.makeGmlFile(code);
			var result = synext.preproc(file.codeEditor, file.readContent());
			var resultBack = synext.postproc(file.codeEditor, result);
			Assert.areEqual(code, resultBack);
		}

	}
}