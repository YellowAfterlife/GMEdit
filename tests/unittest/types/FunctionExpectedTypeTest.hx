package types;

import ui.Preferences;
import test_helpers.LinterHelper;
import massive.munit.Assert;

class FunctionExpectedTypeTest {
	@Test public function testValidTypes() {
		var result = LinterHelper.runLinter("buffer_create(1, buffer_grow, 1);");
		Assert.isTrue(result.problems.length == 0);

		result = LinterHelper.runLinter("buffer_create(1, buffer_u8, 1);");
		js.Lib.debug();
		Assert.isTrue(result.problems.length > 1);
	}
	@Test public function testImplicitType() {
		Preferences.current.linterPrefs.specTypeVar = true;
		var result = LinterHelper.runLinter("var a = string(\"hello\");");
		//Assert.areEqual("string", result.localVariables["a"].type);
	}
}