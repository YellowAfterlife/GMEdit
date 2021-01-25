package linter;
import file.kind.KGml;
import gml.file.GmlFile;
import editors.EditCode;
import parsers.linter.GmlLinter;
import massive.munit.Assert;

class GmlLinterBasicTest {
	public static function runLinter(code:String) {
		var file = new GmlFile("test", "test.gml", KGml.inst, "");
		var editor = new EditCode(file, "ace/mode/gml");
		var linter = new GmlLinter();
		var ok = !linter.run(code, editor, gml.Project.current.version);
		return new GmlLinterTest(linter, ok);
	}
	@Test public function testBasics() {
		var t = runLinter("var a");
		Assert.areEqual(t.warnings.length, 0);
		t = runLinter("if");
		Assert.areNotEqual(t.problems.length, 0);
	}
}
class GmlLinterTest {
	public var linter:GmlLinter;
	public var problems:Array<GmlLinterProblem>;
	public var warnings:Array<GmlLinterProblem>;
	public var errors:Array<GmlLinterProblem>;
	public var isValid:Bool;
	public function new(linter:GmlLinter, isValid:Bool) {
		this.linter = linter;
		this.isValid = isValid;
		warnings = linter.warnings;
		errors = linter.errors;
		problems = linter.warnings.concat(linter.errors);
	}
}