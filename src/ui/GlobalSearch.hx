package ui;
import ace.AceWrap;
import Main.aceEditor;
import Main.window;
import gml.*;
import gml.file.GmlFile;
import js.RegExp;
import js.html.DivElement;
import js.html.Element;
import js.html.InputElement;
import js.html.KeyboardEvent;
import parsers.GmlReader;
import tools.Dictionary;
import tools.NativeString;
import ui.GlobalSeachData;
import haxe.extern.EitherType;
import haxe.Constraints.Function;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class GlobalSearch {
	public static var element:Element;
	public static var fdFind:InputElement;
	public static var fdReplace:InputElement;
	public static var btFind:InputElement;
	public static var btReplace:InputElement;
	public static var btPreview:InputElement;
	public static var btCancel:InputElement;
	public static var cbWholeWord:InputElement;
	public static var cbMatchCase:InputElement;
	public static var cbCheckComments:InputElement;
	public static var cbCheckStrings:InputElement;
	public static var cbCheckObjects:InputElement;
	public static var cbCheckScripts:InputElement;
	public static var cbCheckHeaders:InputElement;
	public static var cbCheckTimelines:InputElement;
	public static var cbCheckMacros:InputElement;
	public static var divSearching:DivElement;
	//
	static function offsetToPos(code:String, till:Int, rowStart:Int):AcePos {
		var pos:Int;
		if (till < rowStart) {
			pos = code.lastIndexOf("\n", till);
			return { column: till - (pos + 1), row: -1 };
		}
		var row = 0;
		pos = code.indexOf("\n", rowStart);
		while (pos <= till && pos >= 0) {
			row += 1;
			rowStart = pos + 1;
			pos = code.indexOf("\n", rowStart);
		}
		return { column: till - rowStart, row: row };
	}
	public static function run(opt:GlobalSearchOpt, ?finish:Void->Void) {
		var pj = Project.current;
		var version = pj.version;
		if (version == gml.GmlVersion.none) return;
		var term:String, rx:RegExp;
		if (Std.is(opt.find, RegExp)) {
			rx = opt.find;
			term = rx.toString();
		} else {
			term = opt.find;
			var eterm = NativeString.escapeRx(term);
			if (opt.wholeWord) eterm = "\\b" + eterm + "\\b";
			rx = new RegExp(eterm, opt.matchCase ? "g" : "ig");
		}
		if (term == "") return;
		var results = "";
		var found = 0;
		var repl:Dynamic = opt.replaceBy;
		var filterFn:Function = opt.findFilter;
		var ctxFilter = opt.headerFilter;
		var isRepl = repl != null;
		var isReplFn = js.Syntax.typeof(repl) == "function";
		var isPrev = opt.previewReplace;
		var saveData = new GlobalSeachData(opt);
		var saveItems = saveData.list;
		var saveItem:GlobalSearchItem;
		var saveCtxItems:Array<GlobalSearchItem>;
		pj.search(function(name:String, path:String, code:String) {
			var q = new GmlReader(code);
			var start = 0;
			var row = 0;
			var ctxName = name;
			saveCtxItems = [];
			saveData.map.set(ctxName, saveCtxItems);
			var ctxStart = 0;
			var ctxCheck = ctxFilter == null || ctxFilter.test("#define " + name);
			var ctxLast = null;
			var out = isRepl ? "" : null;
			var replStart = 0;
			function flush(till:Int) {
				if (!ctxCheck) return;
				var subc:String = q.substring(start, till);
				var mt = rx.exec(subc);
				while (mt != null) {
					var ofs = start + mt.index;
					var eol = code.indexOf("\n", ofs);
					if (eol >= 0) {
						if (StringTools.fastCodeAt(code, eol - 1) == "\r".code) eol -= 1;
					} else eol = code.length;
					var pos = offsetToPos(code, ofs, ctxStart);
					var sol = ofs - pos.column;
					var line = code.substring(sol, eol);
					var ctxLink = ctxName;
					if (pos.row >= 0) ctxLink += ":" + (pos.row + 1);
					if (ctxLink != ctxLast) {
						var curr:Dynamic = mt.length > 1 ? mt : mt[0];
						if (filterFn == null || filterFn(curr)) {
							saveItem = { row: pos.row, code: line, next: null };
							saveItems.push(saveItem);
							saveCtxItems.push(saveItem);
							ctxLast = ctxLink;
							var head = '\n\n// in @[$ctxLink]:\n' + line;
							if (isRepl) {
								var next:String = isReplFn ? repl(curr) : repl;
								out += q.substring(replStart, ofs) + next;
								replStart = ofs + mt[0].length;
								if (mt[0] != next) {
									results += head + "\n" + code.substring(sol, ofs)
										+ next + code.substring(replStart, eol);
								}
							} else results += head;
						}
					}
					found += 1;
					mt = rx.exec(subc);
				}
			}
			while (q.loop) {
				var p = q.pos;
				var c = q.read();
				var p1:Int;
				switch (c) {
					case "/".code: {
						if (!opt.checkComments) switch (q.peek()) {
							case "/".code: {
								flush(p);
								q.skipLine();
								start = q.pos;
							};
							case "*".code: {
								flush(p);
								q.skip(); q.skipComment();
								start = q.pos;
							};
						}
					};
					case '"'.code, "'".code, "@".code, "`".code: {
						if (!opt.checkStrings) {
							q.skipStringAuto(c, version);
							if (q.pos > p + 1) {
								flush(p);
								start = q.pos;
							}
						}
					};
					case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
						if (q.substr(p, 6) == "#macro") {
							if (!opt.checkMacros) {
								q.skipLine();
								q.skipLineEnd();
								start = q.pos;
							}
						} else {
							var ctxNameNext = q.readContextName(name);
							if (ctxNameNext == null) continue;
							flush(p);
							ctxName = ctxNameNext;
							q.skipLine(); q.skipLineEnd();
							ctxStart = q.pos;
							ctxCheck = ctxFilter == null || ctxFilter.test(q.substring(p, q.pos));
							if (opt.checkHeaders) {
								start = p;
								flush(q.pos);
							}
							saveCtxItems = [];
							saveData.map.set(ctxName, saveCtxItems);
							start = q.pos;
						}
					};
				}
			}
			flush(q.pos);
			if (isRepl) out += q.substring(replStart, q.length);
			return isRepl && !isPrev ? out : null;
		}, function() {
			if (finish != null) finish();
			var name = (isRepl ? (isPrev ? "preview: " : "replace: ") : "search: ") + term;
			var head = '// ' + found + ' result';
			if (found != 1) head += "s";
			if (isRepl) {
				if (isPrev) {
					head += " would be replaced";
				} else head += " replaced";
			} else head += " found";
			results = head + ":" + results;
			if (opt.errors != null) {
				results = "/* Errors:\n" + opt.errors + "\n*/\n" + results;
			}
			var file = new GmlFile(name, null, SearchResults, results);
			if (!isRepl) file.searchData = saveData;
			GmlFile.openTab(file);
			window.setTimeout(function() {
				aceEditor.focus();
			});
		}, opt);
	}
	public static function toggle() {
		if (element.style.display == "none") {
			element.style.display = "";
			divSearching.style.display = "none";
			var s = aceEditor.getSelectedText();
			if (s != "" && s != null) fdFind.value = s;
			fdFind.focus();
			fdFind.select();
		} else {
			element.style.display = "none";
		}
	}
	public static function getOptions():GlobalSearchOpt {
		return {
			find: fdFind.value,
			findFilter: null,
			replaceBy: null,
			previewReplace: false,
			headerFilter: null,
			wholeWord: cbWholeWord.checked,
			matchCase: cbMatchCase.checked,
			checkStrings: cbCheckStrings.checked,
			checkObjects: cbCheckObjects.checked,
			checkScripts: cbCheckScripts.checked,
			checkHeaders: cbCheckHeaders.checked,
			checkComments: cbCheckComments.checked,
			checkTimelines: cbCheckTimelines.checked,
			checkMacros: cbCheckMacros.checked,
		};
	}
	public static function runAuto(opt:GlobalSearchOpt) {
		divSearching.style.display = "";
		run(opt, function() {
			element.style.display = "none";
		});
	}
	public static function findAuto(?opt:GlobalSearchOpt) {
		if (opt == null) opt = getOptions();
		runAuto(opt);
	}
	public static function replaceAuto(?opt:GlobalSearchOpt) {
		if (opt == null) opt = getOptions();
		opt.replaceBy = fdReplace.value;
		runAuto(opt);
	}
	public static function previewAuto(?opt:GlobalSearchOpt) {
		if (opt == null) opt = getOptions();
		opt.replaceBy = fdReplace.value;
		opt.previewReplace = true;
		runAuto(opt);
	}
	public static function init() {
		//{
		element = Main.document.querySelector("#global-search");
		fdFind = element.querySelectorAuto('input[name="find-text"]');
		fdReplace = element.querySelectorAuto('input[name="replace-text"]');
		btFind = element.querySelectorAuto('input[name="find"]');
		btReplace = element.querySelectorAuto('input[name="replace"]');
		btPreview = element.querySelectorAuto('input[name="preview"]');
		btCancel = element.querySelectorAuto('input[name="cancel"]');
		divSearching = element.querySelectorAuto('.searching-text');
		//
		cbWholeWord = element.querySelectorAuto('input[name="whole-word"]');
		cbMatchCase = element.querySelectorAuto('input[name="match-case"]');
		cbCheckStrings = element.querySelectorAuto('input[name="check-strings"]');
		cbCheckObjects = element.querySelectorAuto('input[name="check-objects"]');
		cbCheckScripts = element.querySelectorAuto('input[name="check-scripts"]');
		cbCheckHeaders = element.querySelectorAuto('input[name="check-headers"]');
		cbCheckComments = element.querySelectorAuto('input[name="check-comments"]');
		cbCheckTimelines = element.querySelectorAuto('input[name="check-timelines"]');
		cbCheckMacros = element.querySelectorAuto('input[name="check-macros"]');
		//}
		fdFind.onkeydown = function(e:KeyboardEvent) {
			switch (e.keyCode) {
				case KeyboardEvent.DOM_VK_RETURN: btFind.click();
				case KeyboardEvent.DOM_VK_ESCAPE: btCancel.click();
			}
		}
		fdReplace.onkeydown = function(e:KeyboardEvent) {
			switch (e.keyCode) {
				case KeyboardEvent.DOM_VK_RETURN: btReplace.click();
				case KeyboardEvent.DOM_VK_ESCAPE: btCancel.click();
			}
		}
		btFind.onclick = function(_) findAuto();
		btReplace.onclick = function(_) {
			if (!window.confirm("Are you sure that you want to globally replace?"
				+ "\nThis cannot be undone!")) return;
			replaceAuto();
		};
		btPreview.onclick = function(_) previewAuto();
		btCancel.onclick = function(_) element.style.display = "none";
	}
}
typedef GlobalSearchOpt = {
	find:EitherType<String, RegExp>,
	?findFilter:Function,
	?replaceBy:EitherType<String, Function>,
	?previewReplace:Bool,
	wholeWord:Bool,
	matchCase:Bool,
	checkStrings:Bool,
	checkObjects:Bool,
	checkScripts:Bool,
	checkHeaders:Bool,
	checkComments:Bool,
	checkTimelines:Bool,
	checkMacros:Bool,
	?headerFilter:RegExp,
	?errors:String,
};
