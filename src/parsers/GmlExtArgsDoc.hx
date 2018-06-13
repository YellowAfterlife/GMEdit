package parsers;
import ace.AceWrap;
import gml.Project;
import gml.file.GmlFile;
import js.RegExp;
import tools.NativeArray;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtArgsDoc {
	static var rxGmDoc = new RegExp("^(///\\s*\\w*\\()(.*?)(\\).*)$");
	static var rxAfter = new RegExp("^///\\s*@(?:func|function|description|desc)");
	static var rxArg = new RegExp("^(///\\s*(@(?:arg|param|argument))\\s+(\\S+)\\s*)(.*)");
	/** Modifies `/// func(...args)` line as per #args */
	public static function proc1(file:GmlFile):Bool {
		var session = file.getAceSession();
		if (session.getValue().indexOf("#args") < 0) return false;
		var document = session.doc;
		var argData = GmlExtArgs.argData;
		var curr = argData[""];
		var scriptName = file.name;
		var replace = [];
		var iter = new AceTokenIterator(session, 0, 0);
		var tk = iter.getCurrentToken();
		var foundDoc = false;
		var hasArgs = false;
		var nextItem = null;
		var rx = rxGmDoc;
		var startRow = 0;
		function getArgs() {
			var doc = "";
			for (i in 0 ... curr.names.length) {
				if (i > 0) doc += ", ";
				doc += curr.names[i];
				var text = curr.texts[i];
				if (text.startsWith("=")) {
					if (text.charCodeAt(1) == " ".code) doc += " ";
					doc += text;
				}
			}
			return doc;
		}
		function flush():Void {
			if (!hasArgs) return;
			if (foundDoc) {
				if (nextItem != null) replace.unshift(nextItem);
			} else {
				replace.unshift({
					range: AceRange.fromPos(new AcePos(0, startRow)),
					text: "/// " + scriptName + "(" + getArgs() + ")\n"
				});
			}
		}
		while (tk != null) {
			switch (tk.type) {
				case "preproc.define": {
					tk = iter.stepForward();
					if (tk != null) {
						flush();
						scriptName = tk.value;
						curr = argData[scriptName];
						foundDoc = false;
						hasArgs = false;
						nextItem = null;
						startRow = iter.getCurrentTokenRow() + 1;
					}
				};
				case "comment.doc.line" if (!foundDoc): {
					var mt = rx.exec(tk.value);
					if (mt != null) {
						var args = getArgs();
						if (mt[2] != args) {
							var pos = iter.getCurrentTokenPosition();
							var col = pos.column + mt[1].length;
							var row = pos.row;
							nextItem = {
								range: new AceRange(col, row, col + mt[2].length, row),
								text: args
							};
						}
						foundDoc = true;
					}
				};
				case "preproc.args": {
					hasArgs = true;
				};
			}
			tk = iter.stepForward();
		}
		//
		flush();
		for (pair in replace) document.replace(pair.range, pair.text);
		return replace.length > 0;
	}
	/** Adds/removes javadoc argument lines for GMS2 format */
	public static function proc2(file:GmlFile, meta:String):Bool {
		var session = file.getAceSession();
		if (session.getValue().indexOf("#args") < 0) return false;
		var argData = GmlExtArgs.argData;
		var curr = argData[""];
		var names = curr.names;
		var texts = curr.texts;
		var aceDoc = session.doc;
		var iter = new AceTokenIterator(session, 0, 0);
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
								remove.push(new AceRange(0, row, 0, row + 1));
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
		return replace.length > 0 || remove.length > 0 || insert.length > 0;
	}
	public static function proc(file:GmlFile) {
		if (Project.current.version.hasJSDoc()) {
			return proc2(file, ui.Preferences.current.argsFormat);
		} else return proc1(file);
	}
}
