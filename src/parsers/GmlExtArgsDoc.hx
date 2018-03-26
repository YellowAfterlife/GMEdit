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
		var argData = GmlExtArgs.argData;
		var curr = argData[""];
		var names = curr.names;
		var texts = curr.texts;
		var aceDoc = session.doc;
		var iter = new AceTokenIterator(file.session, 0, 0);
		var tk = iter.getCurrentToken();
		var lastRow = -1;
		var count = names.length;
		var rows = [];
		var remove = [];
		var replace = [];
		var insert = [];
		var changed = false;
		var addOffset = 0;
		var delOffset = 0;
		var hasArgs = false;
		NativeArray.resize(rows, count);
		function flush():Void {
			if (!hasArgs) return;
			for (i in 0 ... count) {
				var row = rows[i];
				if (row == null) {
					row = lastRow + 1;
					var text = texts[i];
					if (text != "") text = " " + text;
					insert.push({ row: row, text: '/// $meta ${names[i]}' + text });
					addOffset += 1;
					changed = true;
				} else row += addOffset;
				lastRow = row;
			}
		}
		while (tk != null) {
			switch (tk.type) {
				case "comment.doc.line": {
					var val = tk.value;
					if (rxAfter.test(val)) {
						lastRow = iter.getCurrentTokenRow();
					} else {
						var mt = rxArg.exec(val);
						if (mt != null) {
							meta = mt[2];
							var name = mt[3];
							var text = mt[4];
							var index = names.indexOf(name);
							var row = iter.getCurrentTokenRow() - delOffset;
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
								delOffset += 1;
							}
						}
					}
				}; // comment.doc.line
				case "preproc.args": {
					hasArgs = true;
				};
				case "preproc.define": {
					tk = iter.stepForward();
					if (tk != null) {
						flush();
						lastRow = iter.getCurrentTokenRow() + addOffset;
						curr = argData[tk.value];
						names = curr.names;
						texts = curr.texts;
						count = names.length;
						NativeArray.clearResize(rows, count);
						hasArgs = false;
					}
				};
			}
			tk = iter.stepForward();
		}
		flush();
		//
		for (repl in replace) aceDoc.replace(repl.range, repl.next);
		for (range in remove) aceDoc.remove(range);
		for (q in insert) aceDoc.insertMergedLines({ row: q.row, column: 0 }, [q.text, ""]);
		//
		return true;
	}
}
