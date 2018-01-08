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
ace.define("ace/mode/folding/cstyle", ["require","exports","module","ace/lib/oop","ace/range","ace/mode/folding/fold_mode"], function(require, exports, module) {
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
	
	this.foldingStartMarker = /(\{|\[)[^\}\]]*$|^\s*(\/\*)|#define\b|#event\b|#moment\b|#section\b|#region\b/;
	this.foldingStopMarker = /^[^\[\{]*(\}|\])|^[\s\*]*(\*\/)/;
	this.singleLineBlockCommentRe = /^\s*(\/\*).*\*\/\s*$/;
	this.tripleStarBlockCommentRe = /^\s*(\/\*\*\*).*\*\/\s*$/;
	this.startRegionRe = /^\s*(\/\*|\/\/)#region\b/;
	this.startBlockRe = /^\s*#region\b/;
	this.startScriptRe = /^(?:#define|#event|#section|#moment)\b/;
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
		if (this.startBlockRe.test(line)) return this.getCodeRegionBlock(session, line, row);
		if (this.startRegionRe.test(line)) return this.getCommentRegionBlock(session, line, row);
		
		var match = line.match(this.foldingStartMarker);
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
		var re = /^(?:#define|#event|#section|#moment)\b/;
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

}).call(FoldMode.prototype);

}); // ace.define("ace/mode/folding/cstyle", ...)
//
} // function ace_mode_gml_0
function ace_mode_gml_1() {
// a nasty override for Gutter.update to reset line counter on #define:
var dom = ace.require("ace/lib/dom"); 
var rxDefine = /^(?:#define|#event|#moment)\b/;
var rxSection = /^#section\b/;
ace.require("ace/layer/gutter").Gutter.prototype.update = function(config) {
	var session = this.session;
	var firstRow = config.firstRow;
	var lastRow = Math.min(config.lastRow + config.gutterOffset,  // needed to compensate for hor scollbar
		session.getLength() - 1);
	var fold = session.getNextFoldLine(firstRow);
	var foldStart = fold ? fold.start.row : Infinity;
	var foldWidgets = this.$showFoldWidgets && session.foldWidgets;
	var breakpoints = session.$breakpoints;
	var decorations = session.$decorations;
	var firstLineNumber = session.$firstLineNumber;
	var lastLineNumber = 0;
	
	//
	var resetOnDefine = window.gmlResetOnDefine;
	var checkRow = firstRow;
	var checkToken;
	if (resetOnDefine) while (--checkRow >= 0) {
		//checkToken = session.getTokenAt(checkRow, 0);
		//console.log(checkToken);
		if (rxDefine.test(session.getLine(checkRow))) {
			firstLineNumber = -checkRow;
			break;
		}
	}
	
	var gutterRenderer = session.gutterRenderer || this.$renderer;

	var cell = null;
	var index = -1;
	var row = firstRow;
	while (true) {
		if (row > foldStart) {
			row = fold.end.row + 1;
			fold = session.getNextFoldLine(row, fold);
			foldStart = fold ? fold.start.row : Infinity;
		}
		if (row > lastRow) {
			while (this.$cells.length > index + 1) {
				cell = this.$cells.pop();
				this.element.removeChild(cell.element);
			}
			break;
		}

		cell = this.$cells[++index];
		if (!cell) {
			cell = {element: null, textNode: null, foldWidget: null};
			cell.element = dom.createElement("div");
			cell.textNode = document.createTextNode('');
			cell.element.appendChild(cell.textNode);
			this.element.appendChild(cell.element);
			this.$cells[index] = cell;
		}

		var className = "ace_gutter-cell ";
		if (breakpoints[row])
			className += breakpoints[row];
		if (decorations[row])
			className += decorations[row];
		if (this.$annotations[row])
			className += this.$annotations[row].className;
		var rowText = session.getLine(row);
		var reset = resetOnDefine && rxDefine.test(rowText);
		if (reset) {
			firstLineNumber = -row;
			if (/^#moment\s+\d+\s+.+$/g.test(rowText)) firstLineNumber += 1;
			className += "ace_gutter-define ";
		} else if (rxSection.test(rowText)) {
			className += "ace_gutter-define ";
		}
		
		if (cell.element.className != className)
			cell.element.className = className;

		var height = session.getRowLength(row) * config.lineHeight + "px";
		if (height != cell.element.style.height)
			cell.element.style.height = height;

		if (foldWidgets) {
			var c = foldWidgets[row];
			if (c == null)
				c = foldWidgets[row] = session.getFoldWidget(row);
		}

		if (c) {
			if (!cell.foldWidget) {
				cell.foldWidget = dom.createElement("span");
				cell.element.appendChild(cell.foldWidget);
			}
			var className = "ace_fold-widget ace_" + c;
			if (c == "start" && row == foldStart && row < fold.end.row)
				className += " ace_closed";
			else
				className += " ace_open";
			if (cell.foldWidget.className != className)
				cell.foldWidget.className = className;

			var height = config.lineHeight + "px";
			if (cell.foldWidget.style.height != height)
				cell.foldWidget.style.height = height;
		} else {
			if (cell.foldWidget) {
				cell.element.removeChild(cell.foldWidget);
				cell.foldWidget = null;
			}
		}
		
		var text;
		if (reset) {
			text = "#";
		} else if (gutterRenderer) {
			text = gutterRenderer.getText(session, row);
		} else text = row + firstLineNumber;
		lastLineNumber = text;
		if (text != cell.textNode.data)
			cell.textNode.data = text;
		//
		if (!reset) {
			var argsMt = /#args\s+/.exec(rowText);
			if (argsMt != null) {
				var argsText = rowText.substring(argsMt.index + 5).trimLeft();
				argsMt = argsText.match(
					/(?:,|^)\s*(?:\?\w+|\w+\s*=)/g);
				if (argsMt != null) {
					firstLineNumber += argsMt.length;
					if (!/\w+\s*(?:,|$)/.test(argsText)) firstLineNumber -= 1;
				}
			}
		}
		//
		row++;
	}

	this.element.style.height = config.minHeight + "px";

	if (this.$fixedWidth || session.$useWrapMode)
		lastLineNumber = session.getLength() + firstLineNumber;

	/*var gutterWidth = gutterRenderer 
		? gutterRenderer.getWidth(session, lastLineNumber, config)
		: lastLineNumber.toString().length * config.characterWidth;*/
	gutterWidth = 4 * config.characterWidth;
	
	var padding = this.$padding || this.$computePadding();
	gutterWidth += padding.left + padding.right;
	if (gutterWidth !== this.gutterWidth && !isNaN(gutterWidth)) {
		this.gutterWidth = gutterWidth;
		this.element.style.width = Math.ceil(this.gutterWidth) + "px";
		this._emit("changeGutterWidth", gutterWidth);
	}
};
//
ace.define("ace/mode/gml",["require","exports","module",
	"ace/lib/oop","ace/mode/text","ace/mode/gml_highlight_rules",
	"ace/mode/matching_brace_outdent","ace/mode/behaviour/cstyle","ace/mode/folding/cstyle"
], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var GmlHighlightRules = require("./gml_highlight_rules").GmlHighlightRules;
var MatchingBraceOutdent = require("./matching_brace_outdent").MatchingBraceOutdent;
var CstyleBehaviour = require("./behaviour/cstyle").CstyleBehaviour;
var CStyleFoldMode = require("./folding/cstyle").FoldMode;

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
ace.define("ace/mode/gml_search",["require","exports","module",
	"ace/lib/oop","ace/mode/text","ace/mode/gml_highlight_rules",
	"ace/mode/matching_brace_outdent","ace/mode/behaviour/cstyle","ace/mode/folding/cstyle"
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
