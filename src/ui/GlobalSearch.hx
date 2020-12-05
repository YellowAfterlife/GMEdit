package ui;
import ace.AceMacro.jsRx;
import ace.AceWrap;
import ace.extern.*;
import Main.aceEditor;
import Main.window;
import gml.*;
import electron.Dialog;
import gml.file.GmlFile;
import js.lib.RegExp;
import js.Syntax;
import js.html.DivElement;
import js.html.Element;
import js.html.InputElement;
import js.html.KeyboardEvent;
import synext.GmlExtLambda;
import parsers.GmlReader;
import tools.CharCode;
import tools.Dictionary;
import tools.GmlCodeTools;
import tools.NativeObject;
import tools.NativeString;
import ui.GlobalSeachData;
import haxe.extern.EitherType;
import haxe.Constraints.Function;
import file.kind.gml.*;
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
	public static var cbCheckRooms:InputElement;
	public static var cbCheckMacros:InputElement;
	public static var cbCheckShaders:InputElement;
	public static var cbCheckExtensions:InputElement;
	public static var cbExpandLambdas:InputElement;
	public static var cbRegExp:InputElement;
	public static var cbUnique:InputElement;
	public static var divSearching:DivElement;
	public static var currentPath:String;
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
		if (version == GmlVersion.none) return;
		var showPaths = version.config.searchMode == "directory";
		var term:String, rx:RegExp;
		if (Std.is(opt.find, RegExp)) {
			rx = opt.find;
			if (!rx.global) {
				Main.console.warn("This is not a /g regexp and you are potentially in trouble.");
			}
			term = rx.toString();
		} else {
			term = opt.find;
			var eterm = NativeString.escapeRx(term);
			var eopt:String = opt.matchCase ? "g" : "ig";
			if (opt.wholeWord) {
				if (jsRx(~/^\/\//).test(term)) {
					eterm += "$";
					eopt += "m";
				} else {
					if (jsRx(~/^\w/).test(term)) eterm = "\\b" + eterm;
					if (jsRx(~/\w$/).test(term)) eterm = eterm + "\\b";
				}
			}
			rx = new RegExp(eterm, eopt);
		}
		if (term == "") return;
		var results = "";
		var found = 0;
		var checkRefKind = opt.checkRefKind;
		var repl:Dynamic = opt.replaceBy;
		var filterFn:Function = opt.findFilter;
		var lineFilter = opt.lineFilter;
		var ctxFilter = opt.headerFilter;
		var ctxFilterFn:GlobalSearchCtxFilter = Syntax.typeof(ctxFilter) == "function" ? ctxFilter : null;
		var ctxFilterRx:RegExp = Std.is(ctxFilter, RegExp) ? ctxFilter : null;
		var allowDotPrefix:Bool = !opt.noDotPrefix;
		var isRepl = repl != null;
		var isReplFn = Syntax.typeof(repl) == "function";
		var isPrev = opt.previewReplace;
		var saveData = new GlobalSeachData(opt);
		var saveItems = saveData.list;
		var saveItem:GlobalSearchItem;
		var saveCtxItems:Array<GlobalSearchItem>;
		var canLambda = pj.canLambda() && opt.expandLambdas;
		var lambdaGml:String = null;
		pj.search(function(name:String, path:String, code:String) {
			var lambdaPre:GmlExtLambdaPre;
			if (canLambda) {
				lambdaPre = GmlExtLambda.preInit(pj);
				lambdaPre.gml = lambdaGml;
				code = GmlExtLambda.preImpl(code, lambdaPre);
				lambdaGml = lambdaPre.gml;
			} else lambdaPre = null;
			currentPath = path;
			var q = new GmlReader(code);
			var qSqb:GmlReader = null;
			var start = 0;
			var row = 0;
			var ctxName = name;
			saveCtxItems = [];
			saveData.map.set(ctxName, saveCtxItems);
			var ctxStart = 0;
			var ctxCheck:Bool;
			inline function ctxCheckProc(s:String):Void {
				if (ctxFilterFn != null) {
					ctxCheck = ctxFilterFn(s, path);
				} else if (ctxFilterRx != null) {
					ctxCheck = ctxFilterRx.test(s);
				} else ctxCheck = true;
			}
			ctxCheckProc(name);
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
					if (showPaths) ctxLink = path + "(" + ctxLink + ")";
					if (pos.row >= 0) ctxLink += ":" + (pos.row + 1);
					if (isRepl || ctxLink != ctxLast) {
						// todo: show multiple changes on the same line combined
						var curr:Dynamic = mt.length > 1 ? mt : mt[0];
						if ((allowDotPrefix || !GmlCodeTools.isDotAccessBacktrack(code, ofs))
							&& (filterFn == null || filterFn(curr))
							&& (lineFilter == null || lineFilter(line))
						) {
							saveItem = { row: pos.row, code: line, next: null };
							saveItems.push(saveItem);
							saveCtxItems.push(saveItem);
							ctxLast = ctxLink;
							var head = '\n\n// in @[$ctxLink]';
							if (checkRefKind) {
								var mtEnd = ofs + mt[0].length;
								if (NativeString.endsWith(ctxName, "(properties)")) {
									head += " (properties)";
								} else if (NativeString.startsWith(line, "#event collision:")) {
									head += " (collision)";
								} else {
									var rk = tools.GmlCodeTools.getReferenceKind(q.source, ofs, mtEnd);
									head += " (" + rk.toFullString() + ")";
								}
							}
							head += ':\n' + line;
							if (isRepl) {
								var next:String;
								if (isReplFn) {
									next = repl(curr, {
										ctx: ctxName,
										row: pos.row,
									});
								} else if (mt.length > 1) {
									var li = rx.lastIndex;
									next = NativeString.replaceExt(mt[0], rx, repl);
									rx.lastIndex = li;
								} else next = repl;
								out += q.substring(replStart, ofs) + next;
								replStart = ofs + mt[0].length;
								if (mt[0] != next) {
									results += head + "\n" + code.substring(sol, ofs)
										+ next + code.substring(replStart, eol);
								}
							} else results += head;
							found += 1;
						}
					}
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
							ctxCheckProc(ctxName);
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
			if (isRepl) {
				out += q.substring(replStart, q.length);
				var hasLambda = canLambda && !isPrev && GmlExtLambda.hasHashLambda(out);
				if (canLambda && !isPrev && (hasLambda || lambdaPre.list.length > 0)) {
					var lambdaPost = GmlExtLambda.postInit(name, pj, lambdaPre.list, lambdaPre.map);
					out = GmlExtLambda.postImpl(out, lambdaPost);
					if (out == null) {
						var e = "Failed to update #lambda in " + name + ": " + GmlExtLambda.errorText;
						opt.errors = (opt.errors == null ? e : opt.errors + "\n" + e);
					}
				}
			}
			return isRepl && !isPrev ? out : null;
		}, function() {
			if (finish != null) finish();
			var name:String;
			if (checkRefKind) {
				name = "references";
			} else if (!isRepl) {
				name = "search";
			} else if (isPrev) {
				name = "preview";
			} else {
				name = "replace";
			}
			name += ": " + term;
			var head = '// ' + found + ' result';
			if (found != 1) head += "s";
			if (isRepl) {
				if (isPrev) {
					head += " would be replaced";
				} else head += " replaced";
			} else head += " found";
			results = head + ":" + results;
			//
			if (opt.results != null && NativeString.trimRight(opt.results) != "") {
				results = opt.results + "\n" + results;
			}
			//
			if (opt.errors != null) {
				results = "/* Errors:\n" + opt.errors + "\n*/\n" + results;
			}
			//
			var file = new GmlFile(name, null, KGmlSearchResults.inst, results);
			if (!isRepl) file.searchData = saveData;
			GmlFile.openTab(file);
			window.setTimeout(function() {
				aceEditor.focus();
			});
		}, opt);
	}
	public static function findReferences(id:String, ?extra:GlobalSearchOpt) {
		var opt:GlobalSearchOpt = {
			find: id,
			wholeWord: true,
			matchCase: true,
			checkStrings: jsRx(~/^@?["']/).test(id),
			checkComments: jsRx(~/(?:\/\/|\/\*)/).test(id),
			checkHeaders: true,
			checkScripts: true,
			checkTimelines: true,
			checkObjects: true,
			checkRooms: true,
			checkMacros: true,
			checkShaders: false,
			checkExtensions: true,
			expandLambdas: true,
			checkRefKind: true,
		};
		if (extra != null) {
			NativeObject.fillDefaults(extra, opt);
		} else extra = opt;
		run(extra);
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
		var find:EitherType<String, RegExp>;
		if (!cbRegExp.checked) {
			find = fdFind.value;
		} else try {
			var flags = "g";
			if (!cbMatchCase.checked) flags += "i";
			find = new RegExp(fdFind.value, flags);
		} catch (x:Dynamic) {
			window.alert("Error compiling the regular expression: " + x);
			return null;
		}
		return {
			find: find,
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
			checkRooms: cbCheckRooms.checked,
			checkMacros: cbCheckMacros.checked,
			checkShaders: cbCheckShaders.checked,
			checkExtensions: cbCheckExtensions.checked,
			expandLambdas: cbExpandLambdas.checked
		};
	}
	public static function runAuto(opt:GlobalSearchOpt) {
		divSearching.style.display = "";
		run(opt, function() {
			element.style.display = "none";
		});
	}
	public static function findAuto(?opt:GlobalSearchOpt) {
		if (opt == null) {
			opt = getOptions();
			if (cbUnique.checked) {
				var found = new Dictionary<Bool>();
				opt.findFilter = function(mt:Dynamic) {
					var k:String = Std.is(mt, Array) ? mt[0] : mt;
					if (found[k]) return false;
					found[k] = true;
					return true;
				};
			}
		}
		if (opt != null) runAuto(opt);
	}
	public static function replaceAuto(?opt:GlobalSearchOpt) {
		if (opt == null) opt = getOptions();
		opt.replaceBy = fdReplace.value;
		runAuto(opt);
	}
	public static function previewAuto(?opt:GlobalSearchOpt) {
		if (opt == null) opt = getOptions();
		if (opt == null) return;
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
		cbWholeWord = element.querySelectorAuto('#global-search-whole-word');
		cbMatchCase = element.querySelectorAuto('#global-search-match-case');
		cbCheckStrings = element.querySelectorAuto('#global-search-check-strings');
		cbCheckObjects = element.querySelectorAuto('#global-search-check-objects');
		cbCheckScripts = element.querySelectorAuto('#global-search-check-scripts');
		cbCheckHeaders = element.querySelectorAuto('#global-search-check-headers');
		cbCheckComments = element.querySelectorAuto('#global-search-check-comments');
		cbCheckTimelines = element.querySelectorAuto('#global-search-check-timelines');
		cbCheckMacros = element.querySelectorAuto('#global-search-check-macros');
		cbCheckShaders = element.querySelectorAuto('#global-search-check-shaders');
		cbCheckExtensions = element.querySelectorAuto('#global-search-check-extensions');
		cbCheckRooms = element.querySelectorAuto('#global-search-check-rooms');
		cbExpandLambdas = element.querySelectorAuto('#global-search-expand-lambdas');
		cbRegExp = element.querySelectorAuto('#global-search-regexp');
		cbUnique = element.querySelectorAuto('#global-search-unique');
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
			if (!Dialog.showConfirmWarn("Are you sure that you want to globally replace?"
				+ "\nThis cannot be undone!")) return;
			replaceAuto();
		};
		btPreview.onclick = function(_) previewAuto();
		btCancel.onclick = function(_) element.style.display = "none";
	}
}
typedef GlobalSearchOpt = {
	find:EitherType<String, RegExp>,
	?replaceBy:EitherType<String, Function>,
	/** If `true`, shows pairs of before-after replacement lines but does not modify files. */
	?previewReplace:Bool,
	/**
	 * If provided, is called for each match and returns whether to include/replace it.
	 */
	?findFilter:Function,
	/**
	 * Is called with matched line (same thing you see in search results).
	 * Can return false to ignore the line.
	 */
	?lineFilter:String->Bool,
	/**
	 * Can be a regex to filter context
	 */
	?headerFilter:EitherType<RegExp, GlobalSearchCtxFilter>,
	/** Whole-word match (/\bword\b/) */
	?wholeWord:Bool,
	/** Ignore `.word` */
	?noDotPrefix:Bool,
	/** Case-sensistive match */
	?matchCase:Bool,
	/** Whether to include matches inside strings ("", '') */
	?checkStrings:Bool,
	// per-resource filters:
	?checkObjects:Bool,
	?checkScripts:Bool,
	?checkHeaders:Bool,
	?checkComments:Bool,
	?checkTimelines:Bool,
	?checkMacros:Bool,
	?checkRooms:Bool,
	?checkShaders:Bool,
	?checkExtensions:Bool,
	/** Whether to expand pre-2.3 lambdas instead of showing them separately */
	?expandLambdas:Bool,
	/** Whether to display type of reference (read, write, define, etc.) */
	?checkRefKind:Bool,
	?errors:String,
	/** If set, prepends the given strings before the output */
	?results:String,
};
typedef GlobalSearchCtxFilter = (ctx:String, path:String)->Bool;
