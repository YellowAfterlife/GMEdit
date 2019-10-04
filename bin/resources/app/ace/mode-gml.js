/**
 * ...
 * @author YellowAfterlife
 */
function ace_mode_gml_0() {
//
ace.define("ace/mode/doc_comment_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var DocCommentHighlightRules = function() {
	this.$rules = {
		"start" : [ {
			token : "comment.doc.tag",
			regex : "@[\\w\\d_]+" // TODO: fix email addresses
		}, 
		DocCommentHighlightRules.getTagRule(),
		{
			defaultToken : "comment.doc",
			caseInsensitive: true
		}]
	};
};

oop.inherits(DocCommentHighlightRules, TextHighlightRules);

DocCommentHighlightRules.getTagRule = function(start) {
	return {
		token : "comment.doc.tag.storage.type",
		regex : "\\b(?:TODO|FIXME|XXX|HACK)\\b"
	};
}

DocCommentHighlightRules.getStartRule = function(start) {
	return {
		token : "comment.doc", // doc comment
		regex : "\\/\\*(?=\\*)",
		next  : start
	};
};

DocCommentHighlightRules.getEndRule = function (start) {
	return {
		token : "comment.doc", // closing comment
		regex : "\\*\\/",
		next  : start
	};
};

exports.DocCommentHighlightRules = DocCommentHighlightRules;

}); // ace.define("ace/mode/doc_comment_highlight_rules", ...)
//
ace.define("ace/mode/matching_brace_outdent",["require","exports","module","ace/range"], function(require, exports, module) {
"use strict";

var Range = require("../range").Range;

var MatchingBraceOutdent = function() {};

(function() {

	this.checkOutdent = function(line, input) {
		if (! /^\s+$/.test(line))
			return false;

		return /^\s*\}/.test(input);
	};

	this.autoOutdent = function(doc, row) {
		var line = doc.getLine(row);
		var match = line.match(/^(\s*\})/);

		if (!match) return 0;

		var column = match[1].length;
		var openBracePos = doc.findMatchingBracket({row: row, column: column});

		if (!openBracePos || openBracePos.row == row) return 0;

		var indent = this.$getIndent(doc.getLine(openBracePos.row));
		doc.replace(new Range(row, 0, row, column-1), indent);
	};

	this.$getIndent = function(line) {
		return line.match(/^\s*/)[0];
	};

}).call(MatchingBraceOutdent.prototype);

exports.MatchingBraceOutdent = MatchingBraceOutdent;
}); // ace.define("ace/mode/matching_brace_outdent", ...)
// Edited for "#define" support
ace.define("ace/mode/folding/gmlstyle", ["require","exports","module","ace/lib/oop","ace/range","ace/mode/folding/fold_mode"], function(require, exports, module) {
"use strict";

var oop = require("../../lib/oop");
var Range = require("../../range").Range;
var BaseFoldMode = require("./fold_mode").FoldMode;

var FoldMode = exports.FoldMode = function(commentRegex) {
	if (commentRegex) {
		this.foldingStartMarker = new RegExp(
			this.foldingStartMarker.source.replace(/\|[^|]*?$/, "|" + commentRegex.start)
		);
		this.foldingStopMarker = new RegExp(
			this.foldingStopMarker.source.replace(/\|[^|]*?$/, "|" + commentRegex.end)
		);
	}
};
oop.inherits(FoldMode, BaseFoldMode);

(function() {
	
	this.foldingStartMarker = /(\{|\[)[^\}\]]*$|^\s*(\/\*)|#define\b|#event\b|#moment\b|#section\b|#region\b|#target\b|^\s*(?:case|default)\b/;
	this.foldingStopMarker = /^[^\[\{]*(\}|\])|^[\s\*]*(\*\/)/;
	this.singleLineBlockCommentRe = /^\s*(\/\*).*\*\/\s*$/;
	this.tripleStarBlockCommentRe = /^\s*(\/\*\*\*).*\*\/\s*$/;
	this.startRegionRe = /^\s*(\/\*|\/\/)#region\b/;
	this.startBlockRe = /^\s*#region\b/;
	this.startScriptRe = /^(?:#define|#event|#section|#moment|#target)\b/;
	this.startCaseRe = /^\s*(case|default)\b/;
	this._getFoldWidgetBase = this.getFoldWidget;
	this.getFoldWidget = function(session, foldStyle, row) {
		var line = session.getLine(row);
	
		if (this.singleLineBlockCommentRe.test(line)) {
			if (!this.startRegionRe.test(line) && !this.tripleStarBlockCommentRe.test(line))
				return "";
		}
	
		var fw = this._getFoldWidgetBase(session, foldStyle, row);
	
		if (!fw && this.startRegionRe.test(line))
			return "start"; // lineCommentRegionStart
	
		return fw;
	};

	this.getFoldWidgetRange = function(session, foldStyle, row, forceMultiline) {
		var line = session.getLine(row);
		
		if (this.startScriptRe.test(line)) return this.getScriptRegionBlock(session, line, row);
		var match = line.match(this.startCaseRe);
		if (match) return this.getCaseRegionBlock(session, line, row, match[0].length);
		if (this.startBlockRe.test(line)) return this.getCodeRegionBlock(session, line, row);
		if (this.startRegionRe.test(line)) return this.getCommentRegionBlock(session, line, row);
		
		match = line.match(this.foldingStartMarker);
		if (match) {
			var i = match.index;

			if (match[1])
				return this.openingBracketBlock(session, match[1], row, i);
				
			var range = session.getCommentFoldRange(row, i + match[0].length, 1);
			
			if (range && !range.isMultiLine()) {
				if (forceMultiline) {
					range = this.getSectionRange(session, row);
				} else if (foldStyle != "all")
					range = null;
			}
			
			return range;
		}

		if (foldStyle === "markbegin")
			return;

		var match = line.match(this.foldingStopMarker);
		if (match) {
			var i = match.index + match[0].length;

			if (match[1])
				return this.closingBracketBlock(session, match[1], row, i);

			return session.getCommentFoldRange(row, i, -1);
		}
	};
	
	this.getSectionRange = function(session, row) {
		var line = session.getLine(row);
		var startIndent = line.search(/\S/);
		var startRow = row;
		var startColumn = line.length;
		row = row + 1;
		var endRow = row;
		var maxRow = session.getLength();
		while (++row < maxRow) {
			line = session.getLine(row);
			var indent = line.search(/\S/);
			if (indent === -1)
				continue;
			if  (startIndent > indent)
				break;
			var subRange = this.getFoldWidgetRange(session, "all", row);
			
			if (subRange) {
				if (subRange.start.row <= startRow) {
					break;
				} else if (subRange.isMultiLine()) {
					row = subRange.end.row;
				} else if (startIndent == indent) {
					break;
				}
			}
			endRow = row;
		}
		
		return new Range(startRow, startColumn, endRow, session.getLine(endRow).length);
	};
	this.getCodeRegionBlock = function(session, line, row) {
		var startColumn = line.search(/\s*$/);
		var maxRow = session.getLength();
		var startRow = row;
		
		var re = /^\s*#(end)?region\b/;
		var depth = 1;
		while (++row < maxRow) {
			line = session.getLine(row);
			var m = re.exec(line);
			if (!m) continue;
			if (m[1]) depth--;
			else depth++;

			if (!depth) break;
		}

		var endRow = row;
		if (endRow > startRow) {
			return new Range(startRow, startColumn, endRow, line.length);
		}
	};
	this.getCommentRegionBlock = function(session, line, row) {
		var startColumn = line.search(/\s*$/);
		var maxRow = session.getLength();
		var startRow = row;
		
		var re = /^\s*(?:\/\*|\/\/)#(end)?region\b/;
		var depth = 1;
		while (++row < maxRow) {
			line = session.getLine(row);
			var m = re.exec(line);
			if (!m) continue;
			if (m[1]) depth--;
			else depth++;

			if (!depth) break;
		}

		var endRow = row;
		if (endRow > startRow) {
			return new Range(startRow, startColumn, endRow, line.length);
		}
	};
	this.getScriptRegionBlock = function(session, line, row) {
		var maxRow = session.getLength();
		var startCol = line.length;
		var startRow = row;
		// sections collapse until the next section, but the rest collapses until the next block
		var re = /^#section\b/.test(line)
			? /^(?:#define|#event|#section|#moment|#target)\b/
			: /^(?:#define|#event|#moment|#target)\b/;
		var last = line;
		while (++row < maxRow) {
			line = session.getLine(row);
			if (re.test(line)) break;
		}
		var endRow = row;
		if (endRow > startRow) {
			return new Range(startRow, startCol, endRow - 1, session.getLine(endRow - 1).length);
		}
	};
	this.getCaseRegionBlock = function(session, line, row, col) {
		var iter = new AceTokenIterator(session, row, col);
		var tk = iter.stepForward();
		var depth = 0;
		while (tk) {
			switch (tk.type) {
				case "curly.paren.lparen": depth++; break;
				case "curly.paren.rparen":
					if (--depth < 0) {
						var endRow = iter.getCurrentTokenRow() - 1;
						return new Range(row, line.length,
							endRow, session.getLine(endRow).length);
					}
					break;
				case "keyword":
					switch (tk.value) {
						case "case": case "default":
							var endRow = iter.getCurrentTokenRow() - 1;
							return new Range(row, line.length,
								endRow, session.getLine(endRow).length);
					}
					break;
			}
			console.log(tk);
			tk = iter.stepForward();
		}
		return null;
	}

}).call(FoldMode.prototype);

}); // ace.define("ace/mode/folding/gmlstyle", ...)
//
} // function ace_mode_gml_0
function ace_mode_gml_1() {
// a nasty override for Gutter.update to reset line counter on #define:
var rxDefine = /^(?:#define|#event|#action|#section|#moment|#target)\b/;
var rxLine1 = /^#moment\s+\d+[|\s]\s*.+$|^#event\s+\w+(?:\:\w*)?[|\s]\s*.+$|#section[|\s]\s*.+/;
var rxSection = /^#section\b/;
var Gutter = ace.require("ace/layer/gutter").Gutter;

/**
 * When starting to update gutter, we want to figure out how the starting line number
 * (which will be either 0 or -event number)
 */
var Gutter_update = Gutter.prototype.update;
if (!Gutter_update) throw "Gutter:update is amiss";
Gutter.prototype.update = function(config) {
	var session = this.session;
	this.gmlResetOnDefine = session.$modeId == "ace/mode/gml" && window.gmlResetOnDefine;
	if (this.gmlResetOnDefine) {
		var checkRow = config.firstRow;
		session.$firstLineNumber = 1;
		while (--checkRow >= 0) {
			if (rxDefine.test(session.getLine(checkRow))) {
				session.$firstLineNumber = -checkRow;
				break;
			}
		}
	}
	return Gutter_update.call(this, config);
}

/**
 * This is pretty much the same as above except firstRow is an argument
 */
var Gutter_$renderLines = Gutter.prototype.$renderLines;
if (!Gutter_$renderLines) throw "Gutter:$renderLines is amiss";
Gutter.prototype.$renderLines = function(config, firstRow, lastRow) {
	var session = this.session;
	this.gmlResetOnDefine = session.$modeId == "ace/mode/gml" && window.gmlResetOnDefine;
	if (this.gmlResetOnDefine) {
		var checkRow = firstRow;
		session.$firstLineNumber = 1;
		while (--checkRow >= 0) {
			if (rxDefine.test(session.getLine(checkRow))) {
				session.$firstLineNumber = -checkRow;
				break;
			}
		}
	}
	return Gutter_$renderLines.call(this, config, firstRow, lastRow);
}

/**
 * With few minor changes to ace.js, $renderCell will call $gmlCellClass
 * if gmlResetOnDefine == true, and this is where we reset line number
 * and set the magic variable to replace 0/etc. for it by a "#"
 */
Gutter.prototype.gmlCellClass = function(row, className) {
	var session = this.session;
	var rowText = session.getLine(row);
	var reset = rxDefine.test(rowText);
	if (reset) {
		this.$gmlCellText = "#";
		session.$firstLineNumber = -row;
		if (rxLine1.test(rowText)) session.$firstLineNumber += 1;
		className += "ace_gutter-define ";
	} else if (rxSection.test(rowText)) {
		className += "ace_gutter-define ";
	}
	return className;
}

/**
 * So, for fixed-width mode gutter width is determined from
 * (lineCount - session.$firstLineNumber).toString().length, but we've
 * been messing with that to implement line number resetting on #define,
 * so we need to change that back to zero
 * (ideally, we'd find the longest line number, but that's more work)
 */
var Gutter_$updateGutterWidth = Gutter.prototype.$updateGutterWidth;
Gutter.prototype.$updateGutterWidth = function(config) {
	if (this.gmlResetOnDefine) this.session.$firstLineNumber = 1;
	return Gutter_$updateGutterWidth.call(this, config);
}



ace.define("ace/mode/gml",["require","exports","module",
	"ace/lib/oop","ace/mode/text","ace/mode/gml_highlight_rules",
	"ace/mode/matching_brace_outdent","ace/mode/behaviour/cstyle","ace/mode/folding/gmlstyle"
], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var GmlHighlightRules = require("./gml_highlight_rules").GmlHighlightRules;
var MatchingBraceOutdent = require("./matching_brace_outdent").MatchingBraceOutdent;
var CstyleBehaviour = require("./behaviour/cstyle").CstyleBehaviour;
var CStyleFoldMode = require("./folding/gmlstyle").FoldMode;

var Mode = function() {
	this.HighlightRules = GmlHighlightRules;
	
	this.$outdent = new MatchingBraceOutdent();
	this.$behaviour = new CstyleBehaviour();
	this.foldingRules = new CStyleFoldMode();
};
oop.inherits(Mode, TextMode);

(function() {
	this.lineCommentStart = "//";
	this.blockComment = {start: "/*", end: "*/"};
	
	this.getNextLineIndent = function(state, line, tab) {
		var indent = this.$getIndent(line);

		var tokenizedLine = this.getTokenizer().getLineTokens(line, state);
		var tokens = tokenizedLine.tokens;
		
		if (tokens.length && tokens[tokens.length-1].type.indexOf("comment") >= 0) {
			return indent;
		}

		if (state == "start") {
			var match = line.match(/^.*[\{\(\[]\s*$/);
			if (match) {
				indent += tab;
			}
		}

		return indent;
	};

	this.checkOutdent = function(state, line, input) {
		return this.$outdent.checkOutdent(line, input);
	};

	this.autoOutdent = function(state, doc, row) {
		this.$outdent.autoOutdent(doc, row);
	};

	this.$id = "ace/mode/gml";
}).call(Mode.prototype);

exports.Mode = Mode;
});
//
ace.define("ace/mode/shader",["require","exports","module",
	"ace/lib/oop","ace/mode/text","ace/mode/shader_highlight_rules",
	"ace/mode/matching_brace_outdent","ace/mode/behaviour/cstyle","ace/mode/folding/gmlstyle"
], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var ShaderHighlightRules = require("./shader_highlight_rules").ShaderHighlightRules;
var MatchingBraceOutdent = require("./matching_brace_outdent").MatchingBraceOutdent;
var CstyleBehaviour = require("./behaviour/cstyle").CstyleBehaviour;
var CStyleFoldMode = require("./folding/gmlstyle").FoldMode;

var Mode = function() {
	this.HighlightRules = ShaderHighlightRules;
	
	this.$outdent = new MatchingBraceOutdent();
	this.$behaviour = new CstyleBehaviour();
	this.foldingRules = new CStyleFoldMode();
};
oop.inherits(Mode, TextMode);

(function() {
	this.lineCommentStart = "//";
	this.blockComment = {start: "/*", end: "*/"};
	
	this.getNextLineIndent = function(state, line, tab) {
		var indent = this.$getIndent(line);

		var tokenizedLine = this.getTokenizer().getLineTokens(line, state);
		var tokens = tokenizedLine.tokens;
		
		if (tokens.length && tokens[tokens.length-1].type.indexOf("comment") >= 0) {
			return indent;
		}

		if (state == "start") {
			var match = line.match(/^.*[\{\(\[]\s*$/);
			if (match) {
				indent += tab;
			}
		}

		return indent;
	};

	this.checkOutdent = function(state, line, input) {
		return this.$outdent.checkOutdent(line, input);
	};

	this.autoOutdent = function(state, doc, row) {
		this.$outdent.autoOutdent(doc, row);
	};

	this.$id = "ace/mode/shader";
}).call(Mode.prototype);

exports.Mode = Mode;
});
//
ace.define("ace/mode/markdown",["require","exports","module",
	"ace/lib/oop","ace/mode/text","ace/mode/markdown_highlight_rules",
	"ace/mode/matching_brace_outdent","ace/mode/behaviour/cstyle","ace/mode/folding/fold_mode"
], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var MarkdownHighlightRules = require("./markdown_highlight_rules").MarkdownHighlightRules;
var MatchingBraceOutdent = require("./matching_brace_outdent").MatchingBraceOutdent;
var CstyleBehaviour = require("./behaviour/cstyle").CstyleBehaviour;

var BaseFoldMode = require("./folding/fold_mode").FoldMode;

var FoldMode = exports.FoldMode = function(commentRegex) {
    if (commentRegex) {
        this.foldingStartMarker = new RegExp(
            this.foldingStartMarker.source.replace(/\|[^|]*?$/, "|" + commentRegex.start)
        );
        this.foldingStopMarker = new RegExp(
            this.foldingStopMarker.source.replace(/\|[^|]*?$/, "|" + commentRegex.end)
        );
    }
};
oop.inherits(FoldMode, BaseFoldMode);
(function() {
	this.foldingStartMarker = /(\{)/;
	this.foldingStopMarker = /(\})/;
	this.singleLineBlockCommentRe = /^\s*(\/\*).*\*\/\s*$/;
	this.tripleStarBlockCommentRe = /^\s*(\/\*\*\*).*\*\/\s*$/;
	this.getFoldWidgetRange = function(session, foldStyle, row, forceMultiline) {
		var line = session.getLine(row);
		
		var match = line.match(this.foldingStartMarker);
		if (match) {
			var i = match.index;

			if (match[1]) return this.openingBracketBlock(session, match[1], row, i);
				
			var range = session.getCommentFoldRange(row, i + match[0].length, 1);
			
			if (range && !range.isMultiLine()) {
				if (forceMultiline) {
					range = this.getSectionRange(session, row);
				} else if (foldStyle != "all")
					range = null;
			}
			
			return range;
		}

		if (foldStyle === "markbegin")
			return;

		var match = line.match(this.foldingStopMarker);
		if (match) {
			var i = match.index + match[0].length;

			if (match[1])
				return this.closingBracketBlock(session, match[1], row, i);

			return session.getCommentFoldRange(row, i, -1);
		}
	};
}).call(FoldMode.prototype);

var Mode = function() {
	this.HighlightRules = MarkdownHighlightRules;
	
	this.$outdent = new MatchingBraceOutdent();
	this.$behaviour = new CstyleBehaviour();
	this.foldingRules = new FoldMode();
};
oop.inherits(Mode, TextMode);

(function() {
	this.lineCommentStart = "//";
	this.blockComment = {start: "/*", end: "*/"};
	
	this.getNextLineIndent = function(state, line, tab) {
		var indent = this.$getIndent(line);

		var tokenizedLine = this.getTokenizer().getLineTokens(line, state);
		var tokens = tokenizedLine.tokens;
		
		if (tokens.length && tokens[tokens.length-1].type.indexOf("comment") >= 0) {
			return indent;
		}

		if (state == "start") {
			var match = line.match(/^.*[\{\(\[]\s*$/);
			if (match) {
				indent += tab;
			}
		}

		return indent;
	};

	this.checkOutdent = function(state, line, input) {
		return this.$outdent.checkOutdent(line, input);
	};

	this.autoOutdent = function(state, doc, row) {
		this.$outdent.autoOutdent(doc, row);
	};

	this.$id = "ace/mode/markdown";
}).call(Mode.prototype);

exports.Mode = Mode;
}); // markdown
//
ace.define("ace/mode/gml_search",["require","exports","module",
	"ace/lib/oop","ace/mode/text","ace/mode/gml_highlight_rules",
	"ace/mode/matching_brace_outdent","ace/mode/behaviour/cstyle","ace/mode/folding/gmlstyle"
], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var GmlMode = require("./gml").Mode;

var Mode = function() {
	GmlMode.call(this);
	this.foldingRules = null;
};
(function modifyPrototype() {
	this.$id = "ace/mode/gml_search";
}).call(Mode.prototype);
oop.inherits(Mode, GmlMode);
exports.Mode = Mode;
});
//
} // function ace_mode_gml_1
function ace_mode_gml_2() {
//
} // function ace_mode_gml_2
function AceHighlightImpl() {}
