package parsers;
import ace.AceWrap;
import ace.extern.*;
import gml.Project;
import gml.file.GmlFile;
import js.lib.RegExp;
import tools.NativeArray;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtArgsDoc {
	static var rxGmDocStart = new RegExp("^(///\\s*)$");
	static var rxGmDoc = new RegExp("^(///\\s*\\w*\\()(.*?)(\\).*)$");
	static var rxAfter = new RegExp("^///\\s*@(?:func|function|description|desc)");
	static var rxArg = new RegExp("^(///" // 1 -> until text
		+ "(\\s*)" // 2 -> pre-meta
		+ "(@(?:arg|param|argument))" // 3 -> meta
		+ "(\\s+)" // 4 -> post-meta
		+ "(?:{(.+?)}(\\s+))?" // 5 -> ?type, 6 -> ?post type
		+ "(\\S+)" // 7 -> name
		+ "(\\s*)" // 8 -> after name
		+ ")(.*)" // 9 -> text
	);
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
		var beforeMeta = " ";
		var afterMeta = " ";
		var argData = GmlExtArgs.argData;
		var curr = argData[""];
		var names = curr.names;
		var rxTrim:RegExp = null; {
			var s = Project.current.properties.argNameRegex;
			if (s != null && s.trim() != "") try {
				rxTrim = new RegExp(s);
			} catch (x:Dynamic) {
				Main.console.error("Error parsing argument regex: ", x);
			}
		};
		if (rxTrim != null) for (i in 0 ... names.length) {
			var name = names[i];
			var mt = rxTrim.exec(name);
			if (mt != null && mt[1] != null) names[i] = mt[1];
		}
		var texts = curr.texts;
		var types = curr.types;
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
					text = " " + names[i] + text;
					var type = types[i];
					if (type != "" && type != null) text = ' {$type}' + text;
					insert.push({ row: row, text: '/// ' + meta + text });
					addOffset += 1;
					changed = true;
				} else row += addOffset;
				lastRow = row;
			}
		}
		while (tk != null) {
			var next = true;
			switch (tk.type) {
				case "comment.doc.line": {
					var val = tk.value;
					var tkRow = iter.getCurrentTokenRow();
					var tkCol = iter.getCurrentTokenColumn();
					if (rxGmDocStart.test(val)) {
						tk = iter.stepForward();
						next = false;
						if (tk.type == "comment.meta") {
							val += tk.value;
							tk = iter.stepForward();
							if (tk.type == "comment.doc.line") {
								val += tk.value;
							}
						}
					}
					if (rxAfter.test(val)) {
						lastRow = iter.getCurrentTokenRow();
					} else {
						var mt = rxArg.exec(val);
						if (mt != null) {
							var untilText = mt[1];
							// makes sure that new doc lines use the same convention
							beforeMeta = mt[2];
							meta = mt[3];
							afterMeta = mt[4];
							var type = mt[5]; if (type == null) type = "";
							var afterType = mt[6]; if (afterType == null) afterType = " ";
							var name = mt[7];
							var afterName = mt[8];
							if (afterName == "") afterName = " ";
							var text = mt[9];
							//
							var index = names.indexOf(name);
							var row = iter.getCurrentTokenRow() - delOffset;
							if (index < 0) {
								// argument not used anymore
								remove.push(new AceRange(0, row, 0, row + 1));
								delOffset += 1;
							} else {
								rows[index] = row;
								var updateDoc = false;
								//
								if (text != texts[index] && (
									// (we leave handwritten docs alone)
									text == "" || text.startsWith("= ")
								)) {
									text = texts[index];
									updateDoc = true;
								}
								//
								if (types[index] != "" && type != types[index]) {
									type = types[index];
									updateDoc = true;
								}
								//
								if (updateDoc) {
									var range = iter.getCurrentTokenRange();
									if (!next) range = range.extend(tkRow, tkCol);
									replace.push({
										range: range,
										next: "///" + beforeMeta + meta + afterMeta
											+ (type != "" && type != null ? '{' + type + '}' + afterType : '')
											+ name + (text != "" ? afterName + text : "")
									});
								}
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
			if (next) tk = iter.stepForward();
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
		if (Project.current.version.config.hasJSDoc) {
			return proc2(file, ui.Preferences.current.argsFormat);
		} else return proc1(file);
	}
}
