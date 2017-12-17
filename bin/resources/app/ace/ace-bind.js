//(function() {
function aceGML(id) {
	var ectr = document.getElementById(id).parentElement;
	var editor = ace.edit(id);
	editor.setBehavioursEnabled(false);
	editor.$blockScrolling = Infinity;
	(function enableStatusBar(editor, ectr) {
		var statusBar = document.createElement("div");
		statusBar.className = "ace_status-bar";
		//
		var statusSpan = document.createElement("span");
		statusSpan.setAttribute("width", "0%");
		statusSpan.className = "ace_status-hint";
		statusBar.appendChild(statusSpan);
		//
		var statusHint = document.createElement("span");
		statusHint.innerHTML = "OK!";
		statusHint.id = "ace_status-hint";
		statusBar.appendChild(statusHint);
		editor.statusHint = statusHint;
		//
		ectr.appendChild(statusBar);
		//
		var lang = ace.require("ace/lib/lang");
		var TokenIterator = ace.require("ace/token_iterator").TokenIterator;
		var flowKeywords = (function() {
			var m = "if|then|else|begin|end|for|while|do|until|repeat|switch|case|default|break|continue|with|exit|return|enum|debugger".split("|");
			var r = Object.create(null);
			for (var i = 0; i < m.length; i++) r[m[i]] = true;
			return r;
		})();
		function updateComp(editor, row, col) {
			var it = new TokenIterator(editor.session, row, col);
			var func = null, index = 0, depth = 0;
			var tk, z = 0;
			//console.log("---");
			while (tk = it.getCurrentToken()) {
				var __break = true;
				do {
					//console.log(tk);
					switch (tk.type) {
						case "keyword": if (flowKeywords[tk.value]) continue; else break;
						case "set.operator": continue;
						case "curly.paren.lparen": continue;
						case "curly.paren.rparen": continue;
						case "paren.lparen": depth--; break;
						case "paren.rparen": depth++; break;
						case "punctuation.operator":
							switch (tk.value) {
								case ",": if (depth == 0) index++; break;
								case ";": continue;
								default: //console.log(tk);
							}
							break;
						case "script":
							if (depth < 0) { func = gml_script_doc[tk.value]; continue };
							break;
						case "function":
							if (depth < 0) { func = gml_func_doc[tk.value]; continue };
							break;
						default:
					}
					__break = false;
				} while (false);
				if (__break) break;
				it.stepBackward();
			}
			//
			statusHint.innerHTML = "";
			if (func != null) {
				var args = func.args;
				var argc = args.length;
				var rest = func.rest;
				var out = document.createElement("span");
				out.classList.add("hint");
				out.appendChild(document.createTextNode(func.pre));
				//
				for (var i = 0; i < argc; i++) {
					if (i > 0) out.appendChild(document.createTextNode(", "));
					var span = document.createElement("span");
					span.classList.add("argument");
					if (i == index || i == argc - 1 && index >= i) span.classList.add("current");
					span.appendChild(document.createTextNode(args[i]));
					out.appendChild(span);
				}
				out.appendChild(document.createTextNode(func.post));
				statusHint.appendChild(out);
				statusHint.classList.remove("active");
			}
		}
		var statusUpdate = lang.delayedCall(function(){
			var status = [];
			statusSpan.innerHTML = "";
			function add(val, kind) {
				if (!val) return;
				val = " " + val;
				if (kind) {
					var span = document.createElement("span");
					span.appendChild(document.createTextNode(val));
					span.classList.add(kind);
					statusSpan.appendChild(span);
				} else statusSpan.appendChild(document.createTextNode(val));
			}
			//
			var sel = editor.selection, c = sel.lead;
			//
			add(editor.keyBinding.getStatusText(editor), "status");
			//
			if (editor.commands.recording) add("REC", "recording");
			//
			if (!sel.isEmpty()) {
				var r = editor.getSelectionRange();
				add("(" + (r.end.row - r.start.row) + ":"  + (r.end.column - r.start.column) + ")", "select");
			}
			//
			add("Ln:", "row-label");
			add(c.row + 1, "row");
			add("Col:", "col-label");
			add(c.column + 1, "col");
			//
			if (sel.rangeCount) add("[" + sel.rangeCount + "]", "ranges");
			//
			updateComp(editor, c.row, c.column);
		}.bind(this)).schedule.bind(null, 100);
		editor.on("changeStatus", statusUpdate);
		editor.on("changeSelection", statusUpdate);
		editor.on("keyboardActivity", statusUpdate);
		statusUpdate();
	})(editor, ectr);
	//
	editor.getSession().setMode("ace/mode/gml");
	(function enableAutoCompletion(editor) {
		var langTools = ace.require("ace/ext/language_tools");
		function getCompletionMode(tkType) {
			switch (tkType) {
				case "comment": return 0;
				case "comment.doc": return 0;
				case "string": return 0;
				case "preproc": return 0;
				default: return 1;
			}
		}
		//{ AssetCompleter
		var assetCompleter = {
			getCompletions: function(editor, session, pos, prefix, callback) {
				if (editor.completer) editor.completer.exactMatch = true;
				var tk = session.getTokenAt(pos.row, pos.column);
				var show = getCompletionMode(tk.type) == 1;
				callback(null, show ? gml_asset_ac : []);
			},
		};
		//}
		//{ ScriptCompleter
		var scriptReg = /#define[ \t]+(\w+)(?:\s+\/\/\/\s*(.+))?/g;
		var scriptCompletionsId = -1;
		var scriptCompletions = [];
		function indexScripts() {
			var map = Object.create(null);
			var doc = Object.create(null);
			var cpl = [];
			var rx = scriptReg;
			var src = editor.getValue(), mt;
			rx.lastIndex = -1;
			while (mt = rx.exec(src)) {
				var s = mt[1];
				var d = mt[2];
				map[s] = "script";
				doc[s] = gml_parse_doc(d || s);
				cpl.push({ name: s, value: s, score: 0, meta: "script", doc: d });
				rx.lastIndex = mt.index + 1;
			}
			gml_script_map = map;
			gml_script_doc = doc;
			scriptCompletions = cpl;
		}
		//indexScripts();
		var scriptCompleter = {
			getCompletions: function(editor, session, pos, prefix, callback) {
				var ec = editor.completer;
				if (ec && ec.gatherCompletionsId != scriptCompletionsId) {
					scriptCompletionsId = ec.gatherCompletionsId;
					//indexScripts();
				}
				var tk = session.getTokenAt(pos.row, pos.column);
				var show = getCompletionMode(tk.type) == 1;
				callback(null, show ? scriptCompletions : []);
			},
			getDocTooltip: function(item) {
				return item.doc;
			}
		};
		//}
		//{ KeywordCompleter
		var keywordData = [];
		function addKeywordList(list) {
			for (var i = 0; i < list.length; i++) {
				keywordData.push(list[i]);
			}
		}
		addKeywordList(gml_var_ac);
		addKeywordList(gml_func_ac);
		addKeywordList(gml_const_ac);
		(function() {
			var m = gml_keywords.split("|");
			for (var i = 0; i < m.length; i++) {
				var s = m[i];
				keywordData.push({ name: s, value: s, score: 0, meta: "keyword" });
			}
		})();
		// related: comment out matches.sort(...) in ext-language_tools:setFilter,
		// or it will accidentally shuffle the results.
		keywordData.sort(function(a, b) {
			return a.name < b.name ? -1 : 1;
		});
		var keyWordCompleter = {
			getCompletions: function(editor, session, pos, prefix, callback) {
				if (editor.completer) editor.completer.exactMatch = true;
				var tk = session.getTokenAt(pos.row, pos.column);
				var show = getCompletionMode(tk.type) == 1;
				callback(null, show ? keywordData : []);
			},
			getDocTooltip: function(item) {
				return item.doc;
			}
		};
		//}
		editor.setOptions({
			enableLiveAutocompletion: [
				scriptCompleter, keyWordCompleter, assetCompleter
			]
		});
	})(editor);
	return editor;
}
var editor = aceGML("source");
//})();
