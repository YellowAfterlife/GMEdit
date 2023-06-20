(function() {
	function run(editor,lookup) { // haxe-generated, see .hx._
		var session = editor.getSession();
		var lead = session.selection.lead;
		var iter = new AceTokenIterator(session,lead.row,lead.column);
		var tk = { type : "", value : ""};
		while(tk != null) {
			tk = iter.stepBackward();
			if(tk == null || tk.type != "enum") {
				continue;
			}
			var ename = tk.value;
			tk = iter.stepBackward();
			if(tk == null || tk.type != "text") {
				continue;
			}
			tk = iter.stepBackward();
			if(tk == null || tk.value != "enum") {
				continue;
			}
			tk = iter.stepForward();
			tk = iter.stepForward();
			tk = iter.stepForward();
			var names = [];
			var depth = 1;
			while(tk != null) {
				tk = iter.stepForward();
				if(tk == null) {
					break;
				}
				if(tk.type == "curly.paren.lparen") {
					depth += 1; continue;
				}
				if(tk.type == "curly.paren.rparen") {
					if (--depth <= 0) break; else continue;
				}
				if(tk.type != "enumfield") {
					continue;
				}
				var name = tk.value;
				tk = iter.stepForward();
				if(tk != null && tk.type == "text") {
					tk = iter.stepForward();
				}
				if(tk == null) {
					break;
				}
				switch(tk.value) {
				case ",":case "=":case "}":
					names.push(name);
					if(tk.value != "}") {
						tk = iter.stepForward();
					} else {
						tk = iter.stepBackward();
					}
					break;
				default:
				}
			}
			if(names.length == 0) {
				window.alert("Could not find any fields in enum " + ename);
				break;
			}
			var sep = "\n";
			var line = session.doc.getLine(lead.row);
			var prefix = editor.getSelectedText();
			var _g = 0;
			var _g1 = lead.column - prefix.length;
			while(_g < _g1) sep += line.charAt(_g++) == "\t" ? "\t" : " ";
			var insert = null;
			var last = "";
			var _g2 = 0;
			while(_g2 < names.length) {
				var name1 = names[_g2++];
				if(insert == null) {
					insert = "";
				} else {
					insert += sep;
				}
				if(lookup) {
					last = "" + prefix + "[?\"" + name1 + "\"] = " + ename + "." + name1 + ";";
				} else {
					last = "" + prefix + "[" + ename + "." + name1 + "] = \"" + name1 + "\";";
				}
				insert += last;
			}
			editor.insert(insert,true);
			session.selection.moveTo(lead.row,lead.column - last.length + prefix.length);
			var _g3 = 1;
			var _g4 = names.length;
			while(_g3 < _g4) {
				++_g3;
				editor.execCommand("addCursorAbove");
			}
			editor.focus();
			return;
		}
		window.alert("Could not find an enum. Did you put your cursor after one?");
	};
	var aceCommands = [];
	var palCommands = [];
	GMEdit.register("gen-enum-names", {
		init: function() {
			aceCommands = [{
				name: "genEnumNames",
				exec: function(editor) {
					run(editor, false);
				}
			}, {
				name: "genEnumLookup",
				exec: function(editor) {
					run(editor, true);
				}
			}];
			palCommands = [{
				name: "Macro: generate enum names",
				exec: "genEnumNames",
				title: "Generates an array with index->name matches for the closest enum above the cursor."
			}, {
				name: "Macro: generate enum lookup",
				exec: "genEnumLookup",
				title: "Generates map setters for name->index matches for the closest enum above the cursor."
			}];
			for (var i = 0; i < aceCommands.length; i++) {
				AceCommands.add(aceCommands[i]);
			}
			for (var i = 0; i < palCommands.length; i++) {
				AceCommands.addToPalette(palCommands[i]);
			}
		},
		cleanup: function() {
			for (var i = 0; i < aceCommands.length; i++) {
				AceCommands.remove(aceCommands[i]);
			}
			for (var i = 0; i < palCommands.length; i++) {
				AceCommands.removeFromPalette(palCommands[i]);
			}
		}
	});
})();