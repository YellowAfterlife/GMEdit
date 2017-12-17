package ace;
import ace.AceWrap;
import ace.GmlAPI;
import js.html.DivElement;
import js.html.Element;
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
				case "script": if (depth < 0) { doc = GmlAPI.stdDoc[tk.value]; break; }
				case "function": if (depth < 0) { doc = GmlAPI.stdDoc[tk.value]; break; }
				case "extfunction": if (depth < 0) { doc = GmlAPI.stdDoc[tk.value]; break; }
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
			statusHint.classList.remove("active");
		}
	}
	static function statusUpdate() {
		var editor = Main.aceEditor;
		var sel = editor.selection;
		var pos = sel.lead;
		//
		statusSpan.innerHTML = "";
		function add(value:Dynamic, ?kind:String) {
			if (value == null || value == "") return;
			var text = " " + value;
			if (kind != null) {
				var span = document.createSpanElement();
				span.appendChild(document.createTextNode(text));
				span.className = kind;
				statusSpan.appendChild(span);
			} else statusSpan.appendChild(document.createTextNode(text));
		}
		//
		add(editor.keyBinding.getStatusText(editor), "status");
		if (editor.commands.recording) add("REC", "recording");
		if (!sel.isEmpty()) {
			var r = editor.getSelectionRange();
			add('(${r.end.row - r.start.row}:${r.end.column - r.start.column})', "select");
		}
		//
		add("Ln:", "row-label");
		add(pos.row + 1, "row");
		add("Col:", "col-label");
		add(pos.column + 1, "col");
		if (sel.rangeCount > 0) add('[${sel.rangeCount}]', "ranges");
		//
		updateComp(editor, pos.row, pos.column);
	}
	public static function init(editor:AceWrap, ectr:Element) {
		lang = AceWrap.require("ace/lib/lang");
		tokenIterator = AceWrap.require("ace/token_iterator").TokenIterator;
		//
		statusBar = document.createDivElement();
		statusBar.className = "ace_status-bar";
		//
		statusSpan = document.createSpanElement();
		statusSpan.setAttribute("width", "0%");
		statusSpan.className = "ace_status-hint";
		statusBar.appendChild(statusSpan);
		//
		statusHint = document.createSpanElement();
		statusHint.innerHTML = "OK!";
		statusHint.id = "ace_status-hint";
		statusBar.appendChild(statusHint);
		editor.statusHint = statusHint;
		//
		ectr.appendChild(statusBar);
		//
		var dcUpdate = lang.delayedCall(statusUpdate).schedule.bind(null, 100);
		editor.on("changeStatus", dcUpdate);
		editor.on("changeSelection", dcUpdate);
		editor.on("keyboardActivity", dcUpdate);
		statusUpdate();
	}
}
