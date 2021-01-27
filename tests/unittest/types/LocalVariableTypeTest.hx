package types;

import ui.Preferences;
import test_helpers.LinterHelper;
import massive.munit.Assert;

class LocalVariableTypeTest {
	@Test public function testAssignment() {
		var result = LinterHelper.runLinter("var a:number = 1;");
		//Assert.areEqual("number", result.localVariables["a"].type);
	}
	@Test public function testReassignmentWarning() {
		var result = LinterHelper.runLinter(
			"var ass:number = 1;
			ass = \"string\";
			"
			);
		//Assert.isTrue(result.problems.length > 0);
	}
	@Test public function testImplicitType() {
		Preferences.current.linterPrefs.specTypeVar = true;
		var result = LinterHelper.runLinter("var a = 1;");
		//Assert.areEqual("number", result.localVariables["a"].type);
	}
}