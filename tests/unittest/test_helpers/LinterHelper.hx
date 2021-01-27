package test_helpers;

import gml.file.GmlFileInMemory;
import parsers.GmlSeekData;
import parsers.linter.GmlLinter;
import file.kind.KGml;
import editors.EditCode;

class LinterHelper {
	private static var testCounter : Int = 0;

	public static function runLinter(code:String) {
		var name = "test" + testCounter++;
		var file = new GmlFileInMemory(name, KGml.inst, code);
		var editor = file.codeEditor;
		var linter = new GmlLinter();
		var ok = !linter.run(code, editor, gml.Project.current.version);
		return new LinterHelper(linter, ok);
	}

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

