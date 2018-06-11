package ui;
import ace.AceWrap;
import gml.file.GmlFile;
import js.RegExp;
import tools.Dictionary;
import parsers.GmlReader;
import ui.GlobalSearch;

/**
 * ...
 * @author YellowAfterlife
 */
class GlobalSeachData {
	public var list:Array<GlobalSearchItem> = [];
	/**
	 * "obj_test(create)" -> [{ row: 1, code: "old_code", next: "new_code" }]
	 * Each scope is an array of search results, ordered by row (lowest first)
	 */
	public var map:Dictionary<Array<GlobalSearchItem>> = new Dictionary();
	public var options:GlobalSearchOpt;
	private var saving:Bool = false;
	public function new(opt:GlobalSearchOpt) {
		options = opt;
	}
	private static var sync_rx = new RegExp("// in @\\[(.+):(\\d+)\\]:\r?\n(.*)", "g");
	public function sync(code:String) {
		var rx = sync_rx;
		rx.lastIndex = 0;
		var mt = rx.exec(code);
		for (item in list) item.next = null;
		while (mt != null) {
			var items = map[mt[1]];
			if (items != null) {
				var nextRow = Std.parseInt(mt[2]) - 1;
				for (item in items) {
					var itemRow = item.row;
					if (itemRow == nextRow) {
						item.next = mt[3];
						break;
					} else if (itemRow > nextRow) break;
				}
			}
			mt = rx.exec(code);
		}
	}
	public function save(file:GmlFile) {
		if (saving) return false;
		sync((cast file.editor:editors.EditCode).session.getValue());
		var project = gml.Project.current;
		var version = project.version;
		var errors = "";
		saving = true;
		project.search(function(name:String, path:String, code:String):String {
			var q = new GmlReader(code);
			var out = "";
			var ctxName = name;
			var ctxRowStart = 1;
			var start = 0;
			function flush(till:Int):Void {
				var ctxItems = map[ctxName];
				if (ctxItems == null || ctxItems.length == 0) {
					out += q.substring(start, till);
					return;
				}
				var ctxCode = q.substring(start, till);
				var ctxLen = till - start;
				var ctxStart = 0;
				var ctxRow = ctxRowStart - 2;
				//
				var ctxSol = 0; // ¦var a;
				var ctxEol:Int = 0; // var a;¦\r\n
				var ctxNol:Int = 0; // var a;\r\n¦
				for (item in ctxItems) {
					var ctxLine = null;
					var itemRow = item.row;
					inline function itemError(s:String):Void {
						errors += "// Can't update @[" + ctxName + ":" + (itemRow + 1) + "]: " + s + "\n";
					}
					// this should have been an ugly regular expression instead:
					while (ctxRow < itemRow) {
						ctxSol = ctxNol;
						ctxEol = ctxCode.indexOf("\n", ctxNol);
						if (ctxEol >= 0) {
							ctxNol = ctxEol + 1;
							if (StringTools.fastCodeAt(ctxCode, ctxEol - 1) == "\r".code) {
								ctxEol -= 1;
							}
						} else {
							ctxEol = ctxLen;
							ctxNol = ctxEol;
						}
						if (++ctxRow == itemRow) {
							ctxLine = ctxCode.substring(ctxSol, ctxEol);
						}
					}
					if (ctxLine == null) {
						itemError("End of code reached.");
						break;
					}
					//
					out += ctxCode.substring(ctxStart, ctxSol);
					if (ctxLine == item.code) {
						if (item.next != null) {
							out += item.next;
						} else {
							// no new data
							out += ctxLine;
						}
					} else {
						// mismatch
						out += ctxLine;
						if (item.next != item.code) {
							itemError("Source line changed - please verify manually.");
						}
					}
					ctxStart = ctxEol;
				}
				out += ctxCode.substring(ctxStart);
			} // flush
			while (q.loop) {
				var p = q.pos, p1:Int;
				var c = q.read();
				switch (c) {
					case "/".code: switch (q.peek()) {
						case "/".code: q.skipLine();
						case "*".code: q.skip(); q.skipComment();
					};
					case '"'.code, "'".code, "@".code, "`".code: q.skipStringAuto(c, version);
					case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
						var ctxNameNext = q.readContextName(name);
						if (ctxNameNext == null) continue;
						flush(p);
						ctxName = ctxNameNext;
						ctxRowStart = 0; // (because we'll be checking header line too)
						q.skipLine(); q.skipLineEnd();
						start = p;
					};
					default:
				}
			} // while (q.loop)
			flush(q.pos);
			return out;
		}, function done() {
			saving = false;
			for (item in list) {
				item.code = item.next;
				item.next = null;
			}
			file.savePost();
			if (errors != "") {
				var ef = new GmlFile("save errors", null, SearchResults, errors);
				GmlFile.openTab(ef);
			}
		}, options);
		return true;
	}
}
typedef GlobalSearchItem = {
	row:Int,
	code:String,
	next:String,
};
