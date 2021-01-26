package linter;
import test_helpers.LinterHelper;
import massive.munit.Assert;

class GmlLinterBasicTest {
	@Test public function testBasics() {
		var t = LinterHelper.runLinter("var a");
		Assert.areEqual(t.warnings.length, 0);
		t = LinterHelper.runLinter("if");
		Assert.areNotEqual(t.problems.length, 0);
	}
}