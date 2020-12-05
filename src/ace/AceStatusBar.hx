package ace;
import ace.AceWrap;
import ace.extern.*;
import editors.EditCode;
import file.kind.gml.KGmlScript;
import gml.GmlAPI;
import gml.GmlImports;
import gml.GmlLocals;
import gml.GmlFuncDoc;
import gml.GmlNamespace;
import gml.file.GmlFile;
import js.html.DivElement;
import js.html.Element;
import js.html.MouseEvent;
import js.html.SpanElement;
import Main.document;
import parsers.GmlExtLambda;
import shaders.ShaderAPI;
import tools.Dictionary;
import tools.JsTools;
using tools.NativeString;

/**
 * This handles everything about that status bar on the bottom of the code editor.
 * @author YellowAfterlife
 */
class AceStatusBar {
	public var editor:AceWrap;
	public var statusBar:DivElement;
	public var statusSpan:SpanElement;
	public var statusHint:SpanElement;
	public var contextRow:Int = 0;
	public var contextName:String = null;
	public var ignoreUntil:Float = Main.window.performance.now();
	public var delayTime(default, null):Int = 50;
	public function new() {
		statusBar = document.createDivElement();
		statusBar.className = "ace_status-bar";
		statusSpan = document.createSpanElement();
		statusSpan.className = "ace_status-hint";
		statusSpan.innerHTML = '
			<span class="status" style="display:none">?</span>
			<span class="recording" style="display:none">REC</span>
			<span class="select" style="display:none">(:)</span>
			<span class="row-label">Ln:</span>
			<span class="row">1</span>
			<span class="col-label">Col:</span>
			<span class="col">1</span>
			<span class="ranges" style="display:none"></span>
			<span class="context-pre" style="display:none"></span>
			<span class="context" style="display:none"><span class="context-txt"></span></span>
		';
		statusBar.appendChild(statusSpan);
		//
		statusHint = document.createSpanElement();
		statusHint.className = "ace_status-comp";
		statusBar.appendChild(statusHint);
	}
	public function bind(editor:AceWrap) {
		this.editor = editor;
		editor.statusBar = this;
		var lang = AceWrap.require("ace/lib/lang");
		var dc = lang.delayedCall(update);
		var dcUpdate = function() dc.schedule(delayTime);
		editor.on("changeStatus", dcUpdate);
		editor.on("changeSelection", dcUpdate);
		editor.on("keyboardActivity", dcUpdate);
		editor.container.parentElement.appendChild(statusBar);
	}
	private static var emptyToken:AceToken = { type:"", value:"" };
	public static var canDocData:Dictionary<Bool> = (function() {
		var d = new Dictionary();
		for (k in [
			"asset.script", "function", "extfunction",
			"glsl.function", "hlsl.function",
			"namespace", "macro", "local", "sublocal",
		]) d.set(k, true);
		return d;
	})();
	public static function getDocData(ctx:AceStatusBarDocSearch):Bool {
		var docs:Dictionary<GmlFuncDoc> = null;
		var doc:GmlFuncDoc = null;
		var tk = ctx.tk;
		var iter = ctx.iter;
		inline function flushDocs(d:Dictionary<GmlFuncDoc>):Bool {
			docs = d;
			ctx.docs = docs;
			return docs != null;
		}
		switch (tk.type) { // canDocData mirrors cases
			case "asset.script", "macro.function": return flushDocs(GmlAPI.gmlDoc);
			case "function": return flushDocs(GmlAPI.stdDoc);
			case "glsl.function": return flushDocs(ShaderAPI.glslDoc);
			case "hlsl.function": return flushDocs(ShaderAPI.hlslDoc);
			case "lambda.function": return flushDocs(ctx.lambdas.docs);
			case "extfunction": return flushDocs(GmlAPI.extDoc);
			case "namespace": { // `new Type` or `Type()`
				var name = tk.value;
				var ns:GmlNamespace;
				if (ctx.imports != null) {
					ns = ctx.imports.namespaces[name];
					// map new?:
					tk = iter.stepBackward();
					if (tk != null && tk.type == "text") {
						tk = iter.stepBackward();
						iter.stepForward();
						iter.stepForward();
					} else iter.stepForward();
					if (tk != null && tk.value == "new" && ns != null) {
						doc = ns.docStaticMap["create"];
					}
					if (doc != null) {
						ctx.doc = doc;
						ctx.tk = tk;
						return true;
					}
				}
				//
				return flushDocs(GmlAPI.gmlDoc);
			}
			case "local", "sublocal": { // localVar() can show args from `/// @hint Type:()`
				var imp = ctx.imports;
				if (imp == null) return false;
				var localType = imp.localTypes[tk.value];
				if (localType == null) return false;
				for (iter in 0 ... 2) {
					var ns = iter > 0 ? GmlAPI.gmlNamespaces[localType] : imp.namespaces[localType];
					if (ns == null) continue;
					doc = ns.docInstMap[""];
					if (doc != null) {
						ctx.doc = doc;
						return true;
					}
				}
				return false;
			};
			case "field": { // it might be self.field
				ctx.docs = GmlNamespace.blank;
				return true;
			};
			case "localfield": { // field()?
				if (AceGmlTools.getSelfType({ session: ctx.session, scope: ctx.scope }) != null) {
					ctx.docs = GmlNamespace.blank;
					return true;
				} else return false;
			};
			case "macro": { // macro->function resolution
				var m = GmlAPI.gmlMacros[tk.value];
				if (m != null) {
					var mx = m.expr;
					doc = AceMacro.jsOrx(GmlAPI.gmlDoc[mx], GmlAPI.extDoc[mx], GmlAPI.stdDoc[mx]);
					if (doc != null) {
						ctx.doc = doc;
						return true;
					}
				}
				return false;
			};
			default: return false;
		}
	}
	public static function procDocImport(ctx:AceStatusBarDocSearch):Int {
		var tk = ctx.tk;
		var fnType = tk.type;
		var doc = ctx.docs[tk.value];
		var iter = ctx.iter;
		var imports = ctx.imports;
		var argStart = 0;
		var name = tk.value;
		var type:String;
		if (imports != null) {
			type = null;
			tk = iter.stepBackward();
			if (tk != null && tk.value == ".") {
				iter.stepBackward();
				tk = iter.getCurrentToken();
				//
				if (tk.type == "asset.object") {
					type = tk.value;
				} else if (tk.value == "other") {
					type = AceGmlTools.getOtherType({ session: ctx.session, scope: ctx.scope });
				} else if (tk.value == "self") {
					type = AceGmlTools.getSelfType({ session: ctx.session, scope: ctx.scope });
				} else if (tk.type == "namespace") {
					var nsName = tk.value;
					var td = imports.docs[nsName + "." + name];
					if (td == null) {
						var nsLocal = imports.namespaces[nsName];
						if (nsLocal != null) td = nsLocal.docStaticMap[name];
						
						if (td == null) {
							var nsGlobal = GmlAPI.gmlNamespaces[nsName];
							if (nsGlobal != null) td = nsGlobal.docStaticMap[name];
						}
					}
					if (td != null) doc = td;
				} else if ((tk.type == "local" || tk.type == "sublocal") && imports.localTypes.exists(tk.value)) {
					type = imports.localTypes[tk.value];
				} else iter.stepForward();
			} else {
				if (fnType == "localfield") {
					type = AceGmlTools.getSelfType({ session: ctx.session, scope: ctx.scope });
				}
				doc = AceMacro.jsOr(imports.docs[name], doc);
				tk = iter.stepForward();
			}
			if (type != null) {
				for (iter in 0 ... 2) {
					var ns = (iter > 0 ? GmlAPI.gmlNamespaces[type] : imports.namespaces[type]);
					if (ns == null) continue;
					var td = ns.getInstDoc(name);
					if (td != null) {
						doc = td;
						if (iter == 0
							&& (cast ns:GmlImportNamespace).longen.exists(name)
						) argStart = 1;
						break;
					}
				}
			}
		} else if (!GmlAPI.gmlNamespaces.isEmpty()) {
			type = null;
			tk = iter.stepBackward();
			if (tk != null && tk.value == ".") {
				iter.stepBackward();
				tk = iter.getCurrentToken();
				if (tk.type == "asset.object") {
					type = tk.value;
				} else if (tk.value == "other") {
					type = AceGmlTools.getOtherType({ session: ctx.session, scope: ctx.scope });
				} else if (tk.value == "self") {
					type = AceGmlTools.getSelfType({ session: ctx.session, scope: ctx.scope });
				} else if (tk.type == "namespace") {
					var nsGlobal = GmlAPI.gmlNamespaces[tk.value];
					if (nsGlobal != null) doc = JsTools.or(nsGlobal.docStaticMap[name], doc);
				}
			} else {
				if (fnType == "localfield") {
					type = AceGmlTools.getSelfType({ session: ctx.session, scope: ctx.scope });
				}
			}
			if (type != null) do {
				var ns = GmlAPI.gmlNamespaces[type];
				if (ns == null) continue;
				var td = ns.getInstDoc(name);
				if (td != null) doc = td;
			} while (false);
		}
		ctx.tk = tk;
		ctx.doc = doc;
		return argStart;
	}
	private function updateComp(editor:AceWrap, row:Int, col:Int, imports:GmlImports, lambdas:GmlExtLambda, scope:String) {
		statusHint.innerHTML = "";
		var iter:AceTokenIterator = new AceTokenIterator(editor.session, row, col);
		var sctx:AceStatusBarDocSearch = {
			session: editor.session, scope: scope,
			iter: iter, imports: imports, lambdas: lambdas,
			docs: null, doc: null, tk: null
		};
		var ctk:AceToken = iter.getCurrentToken(); // cursor token
		var parEmpty = false;
		var minDepth = 0; // lowest reached parenthesis depth
		var depth = 0; // current parenthesis depth
		var fkw = GmlAPI.kwFlow;
		if (ctk != null && ctk.type == "paren.lparen") {
			ctk = iter.stepForward();
			if (ctk != null) {
				switch (ctk.type) {
					case "paren.rparen": {
						depth -= ctk.value.length;
						parEmpty = true;
					};
					case "punctuation.operator" if (ctk.value == ";"): ctk = iter.stepBackward();
					case "keyword" if (fkw[ctk.value]): ctk = iter.stepBackward();
					case "preproc.macro": ctk = iter.stepBackward();
					#if !lwedit
					case "curly.paren.lparen", "curly.paren.rparen": {
						ctk = iter.stepBackward();
					};
					#end
				}
			} else ctk = emptyToken;
		}
		// go back to find the likely associated function call:
		var tk:AceToken = ctk;
		var docs:Dictionary<GmlFuncDoc> = null;
		var doc:GmlFuncDoc = null;
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
				case "paren.rparen": depth += tk.value.length;
				case "punctuation.operator" if (tk.value == ";"): break;
				case "paren.lparen": {
					depth -= tk.value.length;
					if (depth < minDepth) {
						minDepth = depth;
						parOpen = tk;
						tk = iter.stepBackward();
						if (tk != null) {
							sctx.tk = tk;
							if (getDocData(sctx)) {
								tk = sctx.tk;
								docs = sctx.docs;
								doc = sctx.doc;
								break;
							} else tk = sctx.tk;
						}
					}
				};
			}
			tk = iter.stepBackward();
		}
		if (docs == null && doc == null) return;
		// find the actual doc:
		var argStart = 0;
		if (doc == null) {
			sctx.tk = tk;
			argStart = procDocImport(sctx); // import magic fixes
			doc = sctx.doc;
			tk = sctx.tk;
		}
		// go forward to verify that cursor token is inside that call:
		depth = -1;
		var argCurr = 0;
		while (tk != null) {
			switch (tk.type) {
				case "paren.lparen", "square.paren.lparen": depth += tk.value.length;
				case "paren.rparen", "square.paren.rparen": depth -= tk.value.length;
				case "punctuation.operator" if (tk.value.contains(",") && depth == 0): argCurr += 1;
			}
			if (tk == ctk) break;
			tk = iter.stepForward();
		}
		argCurr += argStart;
		if ((tk == null ? ctk != emptyToken : tk != ctk) || depth < 0 && !parEmpty) return;
		//
		if (doc != null) {
			var args = doc.args;
			var argc = args.length;
			var out = document.createSpanElement();
			out.className = "hint";
			out.appendChild(document.createTextNode(doc.pre));
			//
			var currArg:SpanElement = null;
			for (i in 0 ... argc) {
				if (i > 0) out.appendChild(document.createTextNode(", "));
				var span = document.createSpanElement();
				span.classList.add("argument");
				if (i == argCurr || i == argc - 1 && argCurr >= i) {
					span.classList.add("current");
					currArg = span;
				}
				span.appendChild(document.createTextNode(args[i]));
				out.appendChild(span);
			}
			out.appendChild(document.createTextNode(doc.post));
			statusHint.appendChild(out);
			if (currArg != null) {
				statusHint.scrollLeft = Std.int(currArg.offsetLeft + currArg.offsetWidth / 2 - statusHint.offsetWidth / 2);
				//currArg.scrollIntoView();
			}
			statusHint.title = out.innerText;
			statusHint.classList.remove("active");
		} else statusHint.title = "";
		statusHint.onclick = null;
	}
	public function setText(s:String) {
		statusHint.innerHTML = "";
		statusHint.appendChild(document.createTextNode(s));
		statusHint.title = s;
		statusHint.onclick = null;
		statusHint.classList.remove("active");
	}
	public function update() {
		if (Main.window.performance.now() < ignoreUntil) return;
		var file = editor.session.gmlFile;
		var codeEditor:EditCode = file != null ? file.codeEditor : null;
		//
		var sel = editor.selection;
		var pos = sel.lead;
		//
		var showRow = pos.row;
		var isScript = JsTools.nca(file, (file.kind is KGmlScript));
		var checkRx = isScript ? GmlAPI.scopeResetRx : GmlAPI.scopeResetRxNF;
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
		// move this elsewhere maybe
		if (file != null && file != ui.WelcomePage.file) file.changed = !session.getUndoManager().isClean();
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
		var locals = codeEditor != null ? codeEditor.locals[scope] : null;
		editor.gmlCompleters.localCompleter.items = locals != null
			? locals.comp : AceWrapCompleter.noItems;
		//
		var imports = codeEditor != null ? codeEditor.imports[scope] : null;
		editor.gmlCompleters.importCompleter.items = imports != null
			? imports.compList : AceWrapCompleter.noItems;
		//
		var lambdas = codeEditor != null ? codeEditor.lambdas[scope] : null;
		editor.gmlCompleters.lambdaCompleter.items = lambdas != null
			? lambdas.comp : AceWrapCompleter.noItems;
		//
		updateComp(editor, pos.row, pos.column, imports, lambdas, scope);
	}
}
typedef AceStatusBarDocSearch = {
	iter:AceTokenIterator,
	docs:Dictionary<GmlFuncDoc>,
	doc:GmlFuncDoc,
	tk:AceToken,
	session:AceSession,
	scope:String,
	imports:GmlImports,
	lambdas:GmlExtLambda,
}
