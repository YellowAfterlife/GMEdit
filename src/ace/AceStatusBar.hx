package ace;
import ace.AceWrap;
import gml.GmlAPI;
import js.html.DivElement;
import js.html.Element;
import js.html.MouseEvent;
import js.html.SpanElement;
import Main.document;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class AceStatusBar {
	static var lang:Dynamic;
	static var tokenIterator:Dynamic;
	static var statusBar:DivElement;
	static var statusSpan:SpanElement;
	static var statusHint:SpanElement;
	static var contextRow:Int = 0;
	static var flowKeywords:Dictionary<Bool> = {
		var q = new Dictionary();
		for (s in "if|then|else|begin|end|for|while|do|until|repeat|switch|case|default|break|continue|with|exit|return|enum|debugger".split("|")) q.set(s, true);
		return q;
	};
	static function updateComp(editor:AceWrap, row:Int, col:Int) {
		var iter:AceTokenIterator = untyped __new__(tokenIterator, editor.session, row, col);
		var tk:AceToken = iter.getCurrentToken();
		var depth = 0, index = 0;
		var doc:GmlFuncDoc = null;
		while (tk != null) {
			switch (tk.type) {
				case "keyword": if (flowKeywords[tk.value]) break;
				case "set.operator": break;
				case "curly.paren.lparen": break;
				case "curly.paren.rparen": break;
				case "paren.lparen": depth -= 1;
				case "paren.rparen": depth += 1;
				case "punctuation.operator": {
					switch (tk.value) {
						case ",": if (depth == 0) index += 1;
						case ";": break;
					}
				};
				case "asset.script": if (depth < 0) { doc = GmlAPI.gmlDoc[tk.value]; break; }
				case "function": if (depth < 0) { doc = GmlAPI.stdDoc[tk.value]; break; }
				case "extfunction": if (depth < 0) { doc = GmlAPI.extDoc[tk.value]; break; }
				default:
			}
			iter.stepBackward();
			tk = iter.getCurrentToken();
		}
		//
		statusHint.innerHTML = "";
		if (doc != null) {
			var args = doc.args;
			var argc = args.length;
			var out = document.createSpanElement();
			out.className = "hint";
			out.appendChild(document.createTextNode(doc.pre));
			//
			for (i in 0 ... argc) {
				if (i > 0) out.appendChild(document.createTextNode(", "));
				var span = document.createElement("span");
				span.classList.add("argument");
				if (i == index || i == argc - 1 && index >= i) span.classList.add("current");
				span.appendChild(document.createTextNode(args[i]));
				out.appendChild(span);
			}
			out.appendChild(document.createTextNode(doc.post));
			statusHint.appendChild(out);
			statusHint.title = out.innerText;
			statusHint.classList.remove("active");
		} else statusHint.title = "";
	}
	static function statusUpdate() {
		//
		var editor = Main.aceEditor;
		var sel = editor.selection;
		var pos = sel.lead;
		//
		var showRow = pos.row;
		var checkRx = new js.RegExp('^(?:#define|#event)[ \t]+([\\w:]+)', '');
		var startRow = showRow + 1;
		var checkExec = null;
		var session = editor.getSession();
		while (--startRow >= 0) {
			checkExec = checkRx.exec(session.getLine(startRow));
			if (checkExec != null) {
				showRow -= startRow + 1;
				break;
			}
		}
		//
		var q = gml.GmlFile.current;
		if (q != null) q.changed = !session.getUndoManager().isClean();
		//
		var ctr = statusSpan, s:String;
		function set(q:String, v:String) {
			var el = ctr.querySelector(q);
			if (v != null && v != "") {
				el.style.display = "";
				el.innerText = v;
			} else el.style.display = "none";
		}
		//
		set(".status", editor.keyBinding.getStatusText(editor));
		set(".recording", editor.commands.recording ? "REC" : null);
		//
		if (!sel.isEmpty()) {
			var r = editor.getSelectionRange();
			set(".select", '(${r.end.row - r.start.row}:${r.end.column - r.start.column})');
		} else set(".select", null);
		//
		set(".row", showRow < 0 ? "#" : "" + (showRow + 1));
		set(".col", "" + (pos.column + 1));
		set(".ranges", sel.rangeCount > 0 ? '[${sel.rangeCount}]' : null);
		//
		var ctxCtr = ctr.querySelector(".context");
		var ctxPre = ctr.querySelector(".context-pre");
		if (checkExec != null) {
			ctxCtr.style.display = "";
			ctxPre.style.display = "";
			var str = checkExec[1];
			var ctxTxt = ctr.querySelector(".context-txt");
			ctxTxt.innerText = str;
			ctxTxt.title = str;
			contextRow = startRow;
		} else {
			ctxCtr.style.display = "none";
			ctxPre.style.display = "none";
			contextRow = -1;
		}
		//
		updateComp(editor, pos.row, pos.column);
	}
	public static function init(editor:AceWrap, ectr:Element) {
		lang = AceWrap.require("ace/lib/lang");
		tokenIterator = AceWrap.require("ace/token_iterator").TokenIterator;
		//
		statusBar = cast document.querySelector(".ace_status-bar");
		statusBar.style.display = "";
		statusSpan = cast statusBar.querySelector(".ace_status-hint");
		statusHint = cast statusBar.querySelector("#ace_status-hint");
		statusBar.querySelector('.context').addEventListener("click", function(e:MouseEvent) {
			Main.aceEditor.gotoLine(contextRow + 1, 0);
		});
		editor.statusHint = statusHint;
		//
		var dcUpdate = lang.delayedCall(statusUpdate).schedule.bind(null, 100);
		editor.on("changeStatus", dcUpdate);
		editor.on("changeSelection", dcUpdate);
		editor.on("keyboardActivity", dcUpdate);
		statusUpdate();
	}
}
