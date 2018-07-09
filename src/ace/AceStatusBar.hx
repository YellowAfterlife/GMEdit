package ace;
import ace.AceWrap;
import gml.GmlAPI;
import gml.GmlImports;
import gml.GmlLocals;
import gml.GmlFuncDoc;
import gml.file.GmlFile;
import js.html.DivElement;
import js.html.Element;
import js.html.MouseEvent;
import js.html.SpanElement;
import Main.document;
import shaders.ShaderAPI;
import tools.Dictionary;

/**
 * This handles everything about that status bar on the bottom of the code editor.
 * @author YellowAfterlife
 */
class AceStatusBar {
	static var lang:Dynamic;
	public static var statusBar:DivElement;
	public static var statusSpan:SpanElement;
	public static var statusHint:SpanElement;
	public static var contextRow:Int = 0;
	public static var contextName:String = null;
	private static var emptyToken:AceToken = { type:"", value:"" };
	static function updateComp(editor:AceWrap, row:Int, col:Int, imports:GmlImports) {
		statusHint.innerHTML = "";
		var iter:AceTokenIterator = new AceTokenIterator(editor.session, row, col);
		var ctk:AceToken = iter.getCurrentToken(); // cursor token
		var parEmpty = false;
		var minDepth = 0; // lowest reached parenthesis depth
		var depth = 0; // current parenthesis depth
		if (ctk != null && ctk.type == "paren.lparen") {
			ctk = iter.stepForward();
			if (ctk != null) {
				if (ctk.type == "paren.rparen") depth -= 1;
			} else ctk = emptyToken;
		}
		// go back to find the likely associated function call:
		var tk:AceToken = ctk;
		var fkw = GmlAPI.kwFlow;
		var docs:Dictionary<GmlFuncDoc> = null;
		var parOpen:AceToken = null;
		while (tk != null) {
			switch (tk.type) {
				case "keyword": if (fkw[tk.value]) break;
				case "preproc.macro": break;
				case "macroname": break;
				case "set.operator": break;
				#if !lwedit
				case "curly.paren.lparen": break;
				case "curly.paren.rparen": break;
				#end
				case "paren.rparen": depth += 1;
				case "punctuation.operator" if (tk.value == ";"): break;
				case "paren.lparen": {
					depth -= 1;
					if (depth < minDepth) {
						minDepth = depth;
						parOpen = tk;
						tk = iter.stepBackward();
						if (tk != null) switch (tk.type) {
							case "asset.script": docs = GmlAPI.gmlDoc;
							case "function": docs = GmlAPI.stdDoc;
							case "glsl.function": docs = ShaderAPI.glslDoc;
							case "hlsl.function": docs = ShaderAPI.hlslDoc;
							case "extfunction": docs = GmlAPI.extDoc;
						}
						if (docs != null) break;
					}
				};
			}
			tk = iter.stepBackward();
		}
		if (docs == null) return;
		// find the actual doc:
		var doc:GmlFuncDoc = docs[tk.value];
		var argStart = 0;
		if (imports != null) {
			var name = tk.value;
			iter.stepBackward();
			tk = iter.getCurrentToken();
			if (tk != null && tk.value == ".") {
				iter.stepBackward();
				tk = iter.getCurrentToken();
				if (tk.type == "namespace") {
					name = tk.value + "." + name;
					doc = AceMacro.jsOr(imports.docs[name], doc);
				} else if (tk.type == "local" && imports.localTypes.exists(tk.value)) {
					var ns = imports.namespaces[imports.localTypes[tk.value]];
					if (ns != null) {
						var td = ns.docs[name];
						if (td != null) {
							doc = td;
							argStart = 1;
						}
					}
				} else iter.stepForward();
			} else {
				doc = AceMacro.jsOr(imports.docs[name], doc);
				iter.stepForward();
			}
		}
		// go forward to verify that cursor token is inside that call:
		depth = -1;
		var argCurr = 0;
		while (tk != null && tk != ctk) {
			switch (tk.type) {
				case "paren.lparen": depth += 1;
				case "paren.rparen": depth -= 1;
				case "punctuation.operator" if (tk.value == "," && depth == 0): argCurr += 1;
			}
			tk = iter.stepForward();
		}
		argCurr += argStart;
		if ((tk == null ? ctk != emptyToken : tk != ctk) || depth < 0) return;
		//
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
				if (i == argCurr || i == argc - 1 && argCurr >= i) span.classList.add("current");
				span.appendChild(document.createTextNode(args[i]));
				out.appendChild(span);
			}
			out.appendChild(document.createTextNode(doc.post));
			statusHint.appendChild(out);
			statusHint.title = out.innerText;
			statusHint.classList.remove("active");
		} else statusHint.title = "";
		statusHint.onclick = null;
	}
	public static function setStatusHint(s:String) {
		statusHint.innerHTML = "";
		statusHint.appendChild(document.createTextNode(s));
		statusHint.title = s;
		statusHint.onclick = null;
		statusHint.classList.remove("active");
	}
	public static var ignoreUntil:Float;
	public static inline var delayTime:Float = 100;
	public static function statusUpdate() {
		if (Main.window.performance.now() < ignoreUntil) return;
		//
		var editor = Main.aceEditor;
		var sel = editor.selection;
		var pos = sel.lead;
		//
		var showRow = pos.row;
		var checkRx = GmlAPI.scopeResetRx;
		var startRow = showRow + 1;
		var session = editor.getSession();
		var resetOnDefine:Bool = GmlExternAPI.gmlResetOnDefine;
		var scope:String = "";
		while (--startRow >= 0) {
			var checkResult = checkRx.exec(session.getLine(startRow));
			if (checkResult != null) {
				scope = checkResult[1];
				if (resetOnDefine) showRow -= startRow + 1;
				break;
			}
		}
		//
		var q = GmlFile.current;
		if (q != ui.WelcomePage.file) q.changed = !session.getUndoManager().isClean();
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
		if (scope != "") {
			ctxCtr.style.display = "";
			ctxPre.style.display = "";
			var ctxTxt = ctr.querySelector(".context-txt");
			ctxTxt.innerText = scope;
			ctxTxt.title = scope;
			contextRow = startRow;
			contextName = scope;
		} else {
			ctxCtr.style.display = "none";
			ctxPre.style.display = "none";
			contextRow = -1;
			contextName = null;
		}
		//
		var locals = GmlLocals.currentMap[scope];
		AceGmlCompletion.localCompleter.items = locals != null
			? locals.comp : AceGmlCompletion.noItems;
		//
		var imports = gml.GmlImports.currentMap[scope];
		AceGmlCompletion.importCompleter.items = imports != null
			? imports.comp : AceGmlCompletion.noItems;
		//
		updateComp(editor, pos.row, pos.column, imports);
	}
	public static function init(editor:AceWrap, ectr:Element) {
		lang = AceWrap.require("ace/lib/lang");
		//
		statusBar = cast document.querySelector(".ace_status-bar");
		statusBar.style.display = "";
		statusSpan = cast statusBar.querySelector(".ace_status-hint");
		statusHint = cast statusBar.querySelector("#ace_status-hint");
		statusBar.querySelector('.context').addEventListener("click", function(e:MouseEvent) {
			Main.aceEditor.gotoLine0(contextRow, 0);
		});
		editor.statusHint = statusHint;
		//
		ignoreUntil = Main.window.performance.now();
		var dcUpdate = lang.delayedCall(statusUpdate).schedule.bind(null, delayTime);
		editor.on("changeStatus", dcUpdate);
		editor.on("changeSelection", dcUpdate);
		editor.on("keyboardActivity", dcUpdate);
	}
}
