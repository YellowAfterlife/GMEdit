/**
 * This is a small plugin demonstrating how to do custom languages.
 * You pretty much just define an Ace mode, make a FileKind for it,
 * and link your FileKind to it's appropriate extensions.
 */
(function() {
	// INI folding rules from original Ace:
	ace.define("ace/mode/folding/ini", ["require", "exports", "module",
		"ace/lib/oop", "ace/range", "ace/mode/folding/fold_mode"
	], function(require, exports, module) {
		"use strict";
		
		var oop = require("../../lib/oop");
		var Range = require("../../range").Range;
		var BaseFoldMode = require("./fold_mode").FoldMode;
		
		var FoldMode = exports.FoldMode = function() {
		};
		oop.inherits(FoldMode, BaseFoldMode);
		
		(function() {
		
			this.foldingStartMarker = /^\s*\[([^\])]*)]\s*(?:$|[;#])/;
		
			this.getFoldWidgetRange = function(session, foldStyle, row) {
				var re = this.foldingStartMarker;
				var line = session.getLine(row);
				
				var m = line.match(re);
				
				if (!m) return;
				
				var startName = m[1] + ".";
				
				var startColumn = line.length;
				var maxRow = session.getLength();
				var startRow = row;
				var endRow = row;
		
				while (++row < maxRow) {
					line = session.getLine(row);
					if (/^\s*$/.test(line))
						continue;
					m = line.match(re);
					if (m && m[1].lastIndexOf(startName, 0) !== 0)
						break;
		
					endRow = row;
				}
		
				if (endRow > startRow) {
					var endColumn = session.getLine(endRow).length;
					return new Range(startRow, startColumn, endRow, endColumn);
				}
			};
		
		}).call(FoldMode.prototype);
	});
	// custom highlighting rules with GML-style tokens... and less code
	ace.define("ace/mode/ini_highlight_rules", [
		"require", "exports", "module",
		"ace/lib/oop", "ace/mode/text_highlight_rules", "ace/mode/folding/fold_mode"
	], function(require, exports, module) {
		"use strict";
		
		var oop = require("../lib/oop");
		var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;
		
		var tk_escape = "constant.language.escape";
		var rx_escape = "\\\\(?:[\\\\0abtrn;#=:]|x[a-fA-F\\d]{4})";
		var tk_key = "ini.variable";
		var tk_set = "ini.set.operator";
		var tk_val = "ini.string";
		
		var IniHighlightRules = function() {
			function rule(tk, rx) { return {token:tk,regex:rx}; }
			function rpop(tk, rx) { return {token:tk,regex:rx,next:"pop"}; }
			function rpush(tk, rx, next) { return {token:tk,regex:rx,push:next}; }
			function rdef(tk) { return { defaultToken: tk }; }
			var rules = [
				rule("ini.comment", /[#;].*$/),
				rule("ini.preproc", /\[.*?\]/),
				rule([tk_key,"text",tk_set,"text"], /(\S+)(\s*)(=)(\s*)$/), // `key=`
				rpush([tk_key,"text",tk_set,"text",tk_val], /(\S+)(\s*)(=)(\s*)(")/, "string2"), // `key="val"`
				rpush([tk_key,"text",tk_set,"text",tk_val], /(\S+)(\s*)(=)(\s*)(')/, "string1"), // `key='val'`
				rpush([tk_key,"text",tk_set,"text"], /(\S+)(\s*)(=)(\s*)/, "string0"), // `key=val`
			];
			this.$rules = {
				start: rules,
				string0: [
					rpop("ini.comment", /[#;].*$/),
					rpop(tk_val, /$/),
					rdef(tk_val)
				],
				string1: [
					rule(tk_escape, rx_escape),
					rpop(tk_val, /($|')/),
					rdef(tk_val)
				],
				string2: [
					rule(tk_escape, rx_escape),
					rpop(tk_val, /($|")/),
					rdef(tk_val)
				],
			};
			this.normalizeRules();
		};
		oop.inherits(IniHighlightRules, TextHighlightRules);
		IniHighlightRules.metaData = {
			fileTypes: ['ini', 'conf'],
			keyEquivalent: '^~I',
			name: 'Ini',
			scopeName: 'source.ini'
		};
		exports.IniHighlightRules = IniHighlightRules;
	});
	// mostly normal Ace
	ace.define("ace/mode/ini", ["require","exports","module",
		"ace/lib/oop","ace/mode/text","ace/mode/ini_highlight_rules",
		"ace/mode/folding/ini"
	], function(require, exports, module) {
		
		var oop = require("../lib/oop");
		var TextMode = require("./text").Mode;
		var IniHighlightRules = require("./ini_highlight_rules").IniHighlightRules;
		var IniFoldMode = require("./folding/ini").FoldMode;
		
		var Mode = function() {
			this.HighlightRules = IniHighlightRules;
			this.foldingRules = new IniFoldMode();
			this.$behaviour = this.$defaultBehaviour;
		};
		oop.inherits(Mode, TextMode);
		
		(function() {
			this.lineCommentStart = ";";
			this.blockComment = null;
			this.$id = "ace/mode/ini";
		}).call(Mode.prototype);
		
		exports.Mode = Mode;
	});
	//
	var FileKind = $gmedit["file.FileKind"];
	var KCode = $gmedit["file.kind.KCode"];
	function KIni() {
		KCode.call(this);
		this.modePath = "ace/mode/ini";
	}
	KIni.prototype = GMEdit.extend(KCode.prototype, {
		// we don't need to override anything if it's pure code
	});
	
	var kini = new KIni();

	GMEdit.register("ini-editor", {
		init: () => {
			FileKind.register("ini", kini);
			FileKind.register("cfg", kini);
			FileKind.register("conf", kini);
		},
		cleanup: () => {
			FileKind.deregister("ini", kini);
			FileKind.deregister("cfg", kini);
			FileKind.deregister("conf", kini);
		}
	});
})();
