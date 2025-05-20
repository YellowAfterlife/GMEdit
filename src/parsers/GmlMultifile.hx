package parsers;
import tools.Dictionary;
import tools.NativeString;
import gml.GmlAPI;
import ui.treeview.TreeView;
import ui.treeview.TreeViewElement;

/**
 * Parses combined code with `#define` headers into individual name-code pairs.
 * @author YellowAfterlife
 */
class GmlMultifile {
	public static var errorText:String;
	public static function split(gmlCode:String, first:String, keyword:String = "define"):GmlMultifilePairs {
		var q = new GmlReader(gmlCode);
		var start = 0;
		var out:GmlMultifilePairs = [];
		var scriptName = first;
		var errors = "";
		var version = GmlAPI.version;
		var keywordLen = keyword.length;
		function flush(till:Int) {
			if (start > 0 || till > start) {
				var next = q.substring(start, till);
				next = NativeString.trimRight(next);
				out.push({ name: scriptName, code: next });
			}
		}
		var row = 1;
		while (q.loop) {
			var c = q.read();
			switch (c) {
				case "\n".code: row += 1;
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); row += q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: row += q.skipStringAuto(c, version);
				case "$".code if (q.isDqTplStart(version)): row += q.skipDqTplString(version);
				case "#".code: if (q.pos == 1 || q.get(q.pos - 2) == "\n".code) {
					if (q.substr(q.pos, keywordLen) == keyword
						&& !q.get(q.pos + keywordLen).isIdent1() // not `#defineButNotReally`
					) {
						flush(q.pos - 1);
						q.skip(6);
						q.skipSpaces0();
						var p = q.pos;
						q.skipIdent1();
						scriptName = q.substring(p, q.pos);
						if (scriptName == "") {
							errors += 'Expected a name at line $row.\n';
						}
						q.skipLine();
						//
						p = q.pos;
						q.skipLineEnd();
						if (q.pos > p) row += 1;
						//
						start = q.pos;
					}
				};
				default:
			}
		} // while (q.loop)
		flush(q.pos);
		if (errors != "") {
			errorText = errors;
			return null;
		} else return out;
	}
}
typedef GmlMultifilePairs = Array<{ name:String, code:String }>;
typedef GmlMultifileData = {
	items:Array<{ name:String, path:String }>,
	tvDir:TreeViewDir,
}
