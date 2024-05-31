package synext;
import gml.Project;
import editors.EditCode;
import parsers.GmlReader;
import synext.SyntaxExtension;
import tools.CharCode;
import ui.Preferences;

/**
 * `(a, b) => c` <-> `function(a, b) /*=>*\/ { return c }`
 * `(a, b) => {` <-> `function(a, b) /*=>*\/ {`
 * @author YellowAfterlife
 */
class GmlExtArrowFunctions extends SyntaxExtension {
	public static var inst:GmlExtArrowFunctions = new GmlExtArrowFunctions();
	public function new() {
		super("()=>", "arrow functions");
	}
	override public function check(editor:EditCode, code:String):Bool {
		return Preferences.current.arrowFunctions;
	}
	override public function preproc(editor:EditCode, code:String):String {
		var q = new GmlReader(code);
		var autoArrow = Project.current.properties.autoArrowFunctions;
		var v = q.version;
		var start = 0;
		var out = "";
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		while (q.loopLocal) {
			if (q.skipCommon() >= 0) continue;
			var p = q.pos;
			var c:CharCode = q.read();
			if (c != "f".code || !q.skipIfIdentEquals("unction")) continue;
			q.skipSpaces1_local();
			
			// skip over (...)...
			var parStart = q.pos;
			if (q.read() != "(".code) continue;
			var depth = 1;
			while (q.loopLocal) {
				if (q.skipCommon() >= 0) continue;
				switch (q.read()) {
					case "(".code: depth++;
					case ")".code: if (--depth <= 0) break;
				}
			}
			if (depth > 0) continue;
			var parEnd = q.pos;
			
			
			var beforeSpStart = q.pos;
			q.skipSpaces1_local();
			var beforeSpEnd = q.pos;
			
			var afterSpStart, afterSpEnd;
			if (q.skipIfStrEquals("/*=>*/")) {
				afterSpStart = q.pos;
				q.skipSpaces1_local();
				afterSpEnd = q.pos;
			} else {
				if (!autoArrow) continue;
				afterSpStart = beforeSpStart;
				afterSpEnd = beforeSpEnd;
			}
			
			if (!q.skipIfEquals("{".code)) continue;
			if (q.skipIfEquals(";".code)) { // ()=>;stat
				var statStart = q.pos;
				q.skipComplexStatement(editor);
				var stat = q.substring(statStart, q.pos);
				if (!q.skipIfEquals("}".code)) continue;
				stat = preproc(editor, stat);
				flush(p);
				out += q.substring(parStart, parEnd)
					+ q.substring(beforeSpStart, beforeSpEnd)
					+ "=>"
					+ q.substring(afterSpStart, afterSpEnd)
					+ ";" + stat;
			} else if (q.skipIfIdentEquals("return")) { // ()=>expr
				q.skipIfEquals(" ".code);
				var exprStart = q.pos;
				q.skipComplexExpr(editor);
				var exprEnd = q.pos;
				if (!q.skipIfEquals("}".code)) continue;
				var expr = q.substring(exprStart, exprEnd);
				expr = preproc(editor, expr);
				flush(p);
				out += q.substring(parStart, parEnd)
					+ q.substring(beforeSpStart, beforeSpEnd)
					+ "=>"
					+ q.substring(afterSpStart, afterSpEnd)
					+ expr;
			} else { // ()=>{block}
				flush(p);
				out += q.substring(parStart, parEnd)
					+ q.substring(beforeSpStart, beforeSpEnd)
					+ "=>"
					+ q.substring(afterSpStart, afterSpEnd)
					+ q.substring(afterSpEnd, q.pos);
			}
			start = q.pos;
		}
		if (start == 0) return code;
		flush(q.pos);
		return out;
	}
	function postproc_sub(q:GmlReader, editor:EditCode):String {
		var start = q.pos - 1;
		var out = "";
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		var found = false;
		while (q.loopLocal) {
			if (q.skipCommon() >= 0) continue;
			switch (q.read()) {
				case "(".code:
					var p = q.pos - 1;
					var sub = postproc_sub(q, editor);
					if (sub != null) {
						flush(p);
						out += sub;
						start = q.pos;
					}
				case ")".code: found = true; break;
			}
		}
		var parEnd = q.pos;
		if (!found) {
			if (out == "") return null;
			flush(q.pos);
			return out;
		}
		
		var beforeSpStart = q.pos;
		q.skipSpaces1_local();
		var beforeSpEnd = q.pos;
		
		if (!q.skipIfStrEquals("=>")) {
			if (out == "") return null;
			flush(q.pos);
			return out;
		}
		
		var afterSpStart = q.pos;
		q.skipSpaces1_local();
		var afterSpEnd = q.pos;
		
		flush(parEnd);
		out = "function" + out + q.substring(beforeSpStart, beforeSpEnd);
		if (!Project.current.properties.autoArrowFunctions) {
			out += "/*=>*/" + q.substring(afterSpStart, afterSpEnd);
		}
		
		if (q.skipIfEquals(";".code)) { // =>;stat
			var statStart = q.pos;
			q.skipComplexStatement(editor);
			var stat = q.substring(statStart, q.pos);
			stat = postproc(editor, stat);
			return out + "{;" + stat + "}";
		} else if (!q.skipIfEquals("{".code)) { // =>expr
			var exprStart = q.pos;
			q.skipComplexExpr(editor);
			var expr = q.substring(exprStart, q.pos);
			expr = postproc(editor, expr);
			return out + "{return " + expr + "}";
		} else { // =>{block}
			return out + "{";
		}
	}
	override public function postproc(editor:EditCode, code:String):String {
		var q = new GmlReader(code);
		var v = q.version;
		//
		var start = 0;
		var out = "";
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		while (q.loopLocal) {
			if (q.skipCommon() >= 0) continue;
			switch (q.read()) {
				case "(".code:
					var p = q.pos - 1;
					var sub = postproc_sub(q, editor);
					if (sub != null) {
						flush(p);
						out += sub;
						start = q.pos;
					}
			}
		}
		
		if (start == 0) return code;
		flush(q.pos);
		return out;
	}
}