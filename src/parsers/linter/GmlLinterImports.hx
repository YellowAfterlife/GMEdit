package parsers.linter;
import parsers.GmlExtImport;
import gml.GmlImports;
import tools.CharCode;

/**
 * There was going to be more code here but then I realized that I can just
 * make it run a GmlExtImport pass without rewriting anything by hand
 * @author YellowAfterlife
 */
@:access(parsers.linter.GmlLinter)
@:access(parsers.GmlExtImport)
class GmlLinterImports {
	public static function proc(self:GmlLinter, dotStart:Int, imp:GmlImports, nv:String):Null<Bool> {
		var q = self.reader;
		var dotPos = -1;
		var dotFull:String;
		var origPos = q.pos;
		if (q.peek() == ".".code && q.peek(1).isIdent0_ni()) {
			dotPos = q.pos;
			q.skip();
			q.skipIdent1();
			dotFull = q.substring(dotStart, q.pos);
		} else dotFull = nv;
		//
		GmlExtImport.errorText = "";
		var next = GmlExtImport.post_procIdent(q, imp, dotStart, dotPos, dotFull);
		if (next != null) {
			q.pushSource(next);
			return false;
		}
		q.pos = origPos;
		return null;
	}
}
