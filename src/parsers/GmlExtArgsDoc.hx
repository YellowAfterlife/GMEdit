package parsers;
import ace.AceWrap;
import gml.file.GmlFile;
import js.RegExp;
import tools.NativeArray;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtArgsDoc {
	static var rxAfter = new RegExp("^///\\s*@(?:func|function|description|desc)");
	static var rxArg = new RegExp("^(///\\s*(@(?:arg|param|argument))\\s+(\\S+)\\s*)(.*)");
	public static function proc(file:GmlFile, meta:String):Bool {
		var session = file.session;
		if (session.getValue().indexOf("#args") < 0) return false;
		var names = GmlExtArgs.argNames;
		var texts = GmlExtArgs.argTexts;
		var aceDoc = session.doc;
		var iter = new AceTokenIterator(file.session, 0, 0);
		var tk = iter.getCurrentToken();
		var lastRow = -1;
		var count = names.length;
		var rows = [];
		var changed = false;
		var rowOffset = 0;
		var remove = [];
		var replace = [];
		var hasArgs = false;
		NativeArray.resize(rows, count);
		while (tk != null) {
			if (tk.type == "comment.doc.line") {
				var val = tk.value;
				if (rxAfter.test(val)) {
					lastRow = iter.getCurrentTokenPosition().row;
				} else {
					var mt = rxArg.exec(val);
					if (mt != null) {
						meta = mt[2];
						var name = mt[3];
						var text = mt[4];
						var index = names.indexOf(name);
						var row = iter.getCurrentTokenPosition().row + rowOffset;
						if (index >= 0) {
							rows[index] = row;
							if (text != texts[index] && (
								text == "" || text.startsWith("= ")
							)) {
								replace.push({
									range: iter.getCurrentTokenRange(),
									next: mt[1] + texts[index]
								});
							}
						} else {
							remove.push({
								start: { row: row, column: 0 },
								end: { row: row + 1, column: 0 }
							});
							rowOffset -= 1;
						}
					}
				}
			} else if (tk.type == "preproc.argrs") hasArgs = true;
			tk = iter.stepForward();
		}
		if (!hasArgs) return false;
		for (repl in replace) aceDoc.replace(repl.range, repl.next);
		for (range in remove) aceDoc.remove(range);
		var rowOffset = 0;
		for (i in 0 ... count) {
			var row = rows[i];
			if (row == null) {
				row = lastRow + 1;
				var text = texts[i];
				if (text != "") text = " " + text;
				aceDoc.insertMergedLines({ row: row, column: 0 }, [
					'/// $meta ${names[i]}' + text, ""
				]);
				rowOffset += 1;
				changed = true;
			} else row += rowOffset;
			lastRow = row;
		}
		return true;
	}
}
